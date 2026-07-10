# CloudStack Firewall Issues

## Known Issues

### Error 530: Failed to create firewall rule

**Cause:** CloudStack reuses public IPs that retain firewall rules from previous deployments.

**Solution:** This terraform configuration uses `managed = true` on firewall resources, which automatically handles cleanup. If issues persist, check CloudStack UI for conflicting rules.

### Error 530: Failed to delete network

**Cause:** CloudStack has a known limitation preventing network deletion.

**Impact:** Networks accumulate over time but don't block new deployments (CloudStack allows duplicate names).

**Workaround:** Orphaned networks must be cleaned up by CloudStack administrators.

### Website not accessible from external IP

**Symptom:** Website works locally (`curl localhost`) but not from external IP.

**Check:** 
1. Verify firewall rules exist in CloudStack UI
2. Check ingress rules on the public IP (ports 80, 443, 22)
3. Verify port forwarding is configured correctly

**Note:** The terraform configuration includes `managed = true` to automatically handle firewall rule lifecycle.
