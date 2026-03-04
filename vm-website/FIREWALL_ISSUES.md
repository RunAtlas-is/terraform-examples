# CloudStack Firewall Rules Issue - Investigation Report

## Executive Summary

**Root Cause:** CloudStack reuses public IP addresses that retain firewall rules from previous deployments, causing error 530 "Failed to create firewall rule" when terraform tries to create new firewall rules.

**Immediate Workaround:** Manually delete conflicting firewall rules before running `terraform apply`.

**Permanent Fix:** Set `managed = true` in the `cloudstack_firewall` resource configuration.

## Detailed Findings

### 1. Root Cause Analysis

The error 530 "Failed to create firewall rule" occurs because:

1. **IP Address Reuse:** CloudStack reuses public IP addresses from a pool. When an IP is disassociated, it goes back to the pool but retains its firewall rules.

2. **Firewall Rule Persistence:** Firewall rules are not automatically deleted when:
   - An IP address is disassociated
   - Terraform destroy is run (when `managed = false`, which is the default)

3. **Conflict on Re-creation:** When terraform tries to create firewall rules on a reused IP, it conflicts with existing rules, causing error 530.

### 2. Evidence

**First Deployment (149.126.81.28):**
- ✓ Succeeded initially
- Resources created successfully

**Cleanup Attempt:**
- `terraform destroy` ran
- VMs destroyed successfully
- Firewall rules deleted successfully (when terraform manages them)
- IP addresses disassociated successfully
- **Networks failed to delete with error 530**

**Second Deployment Attempt:**
- CloudStack reused IP 149.126.81.28 (same IP ID: eba6352a-90d1-4138-b5cd-1ab0785cfde0)
- IP still had firewall rule for port 22 from previous deployment
- Terraform tried to create new firewall rules
- **Conflict occurred → Error 530**

### 3. CloudStack API Behavior

**Error 530 occurs in multiple scenarios:**
- Creating firewall rules when rules already exist on the IP
- Deleting networks (persistent issue in CloudStack)
- The error is a CloudStack internal error, not a terraform issue

**Resource Cleanup Order:**
1. Port forwarding rules ✓
2. Firewall rules ✓
3. VMs ✓
4. IP addresses (disassociate) ✓
5. Networks ✗ (Error 530 - CloudStack bug/limitation)

### 4. Terraform Provider Behavior

**Default behavior (`managed = false`):**
- Terraform only manages firewall rules it creates
- Does NOT delete pre-existing firewall rules
- Safer option (won't delete manually created rules)

**With `managed = true`:**
- Terraform manages ALL firewall rules for the IP
- Automatically deletes any rules not in terraform config
- Prevents conflicts with leftover rules
- **Recommended for this use case**

## Manual Work Required

### Before First Deployment (Clean Slate)

If starting fresh, no manual work needed.

### Before Re-deployment (After Previous Destroy)

1. **Check for leftover firewall rules:**
   ```bash
   cmk list firewallrules ipaddressid=<IP_ID>
   ```

2. **Delete conflicting firewall rules:**
   ```bash
   cmk delete firewallrule id=<RULE_ID>
   ```

3. **Check for orphaned networks:**
   ```bash
   cmk list networks filter=name webserver-network
   ```

4. **Attempt network cleanup (may fail with error 530):**
   ```bash
   cmk delete network id=<NETWORK_ID> cleanup=true
   ```

### Orphaned Networks Issue

CloudStack has a bug/limitation where networks cannot be deleted even after all resources are removed. This results in error 530 "Failed to delete network".

**Impact:** Networks accumulate over time but don't prevent new deployments (CloudStack allows duplicate network names with unique IDs).

**Workaround:** None currently known. Networks must be cleaned up by CloudStack administrators or through backend database operations.

## Recommended Solutions

### Solution 1: Use Managed Firewall Rules (Recommended)

**Modify terraform configuration:**

```hcl
resource "cloudstack_firewall" "ingress" {
  ip_address_id = cloudstack_ipaddress.webserver_ip.id
  managed       = true  # Add this line

  rule {
    protocol  = "tcp"
    ports     = ["80"]
    cidr_list = ["0.0.0.0/0"]
  }

  # ... other rules
}

resource "cloudstack_egress_firewall" "egress" {
  network_id = cloudstack_network.webserver_network.id
  managed    = true  # Add this line

  rule {
    # ... rules
  }
}
```

**Benefits:**
- Automatically cleans up leftover firewall rules
- Prevents error 530 on re-deployment
- Terraform manages the complete lifecycle

**Risks:**
- Will delete ANY firewall rules on the IP/network, including manually created ones
- Use with caution in shared environments

### Solution 2: Manual Cleanup Script

Create a cleanup script to run before deployments:

```bash
#!/bin/bash
# cleanup-cloudstack-resources.sh

echo "Checking for leftover firewall rules..."
IPS=$(cmk list publicipaddresses 2>&1 | jq -r '.publicipaddress[] | select(.associatednetworkname == "webserver-network") | .id')

for IP_ID in $IPS; do
  echo "Checking IP: $IP_ID"
  RULES=$(cmk list firewallrules ipaddressid=$IP_ID 2>&1 | jq -r '.firewallrule[]?.id // empty')
  
  for RULE_ID in $RULES; do
    echo "Deleting firewall rule: $RULE_ID"
    cmk delete firewallrule id=$RULE_ID
  done
done

echo "Cleanup complete!"
```

### Solution 3: Unique Resource Names

Use unique identifiers for each deployment to avoid conflicts:

```hcl
resource "cloudstack_network" "webserver_network" {
  name = "webserver-network-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  # ... other config
}
```

**Drawback:** Doesn't solve the orphaned resources problem.

## Testing Results

### Test 1: Initial Deployment
- ✓ Network created
- ✓ IP address acquired
- ✓ Firewall rules created
- ✓ VM created
- ✓ Website accessible

### Test 2: Destroy and Re-deploy (without managed=true)
- ✓ Destroy succeeded (except network deletion)
- ✗ Re-deploy failed with error 530 (firewall rule conflict)
- ✓ After manual firewall rule deletion, re-deploy succeeded

### Test 3: Destroy and Re-deploy (with managed=true)
- Not yet tested
- Expected: Should succeed without manual intervention

## CloudStack/Terraform Issues Documented

1. **Error 530 on network deletion:** CloudStack bug/limitation
   - Occurs even with `cleanup=true` flag
   - No VMs or resources attached
   - Networks accumulate but don't block deployments

2. **Firewall rule persistence:** CloudStack design
   - Rules persist after IP disassociation
   - Rules persist after terraform destroy (when managed=false)
   - Can cause conflicts on IP reuse

3. **IP address reuse:** CloudStack design
   - IPs are reused from pool
   - Reused IPs may have leftover firewall rules
   - Can cause error 530 on terraform apply

4. **VM hostname conflicts:** CloudStack behavior
   - Hostnames persist in network domain
   - Can cause conflicts when reusing same network
   - Workaround: Use unique VM names or clean up networks

## Recommendations for Atlas Cloud Team

1. **Short-term:**
   - Add `managed = true` to firewall resources in terraform examples
   - Document the manual cleanup procedure
   - Consider adding cleanup script to repository

2. **Medium-term:**
   - Investigate CloudStack network deletion issue (error 530)
   - Consider implementing periodic cleanup of orphaned resources
   - Add monitoring for accumulated orphaned networks

3. **Long-term:**
   - Work with CloudStack community to fix network deletion bug
   - Consider implementing resource naming conventions to avoid conflicts
   - Add automated testing for destroy/re-deploy cycles

## Files to Update

1. **vm-website/main.tf:**
   - Add `managed = true` to `cloudstack_firewall.ingress`
   - Add `managed = true` to `cloudstack_egress_firewall.egress`

2. **vm-website/README.md:**
   - Add troubleshooting section for error 530
   - Document manual cleanup procedure
   - Explain managed firewall rules

3. **vm-website/scripts/cleanup.sh (new):**
   - Create cleanup script for manual intervention

## Conclusion

The firewall rules issue is caused by CloudStack's IP reuse mechanism combined with firewall rule persistence. The immediate workaround is manual cleanup, but the permanent fix is to use `managed = true` in terraform configuration. The network deletion error 530 is a separate CloudStack issue that doesn't block deployments but causes resource accumulation over time.
