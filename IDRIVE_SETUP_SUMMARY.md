# iDrive e2 Storage Setup - Quick Reference

## What Was Configured

✅ **AWS SDK S3 Gem**: Added `aws-sdk-s3` to Gemfile
✅ **Storage Configuration**: Created iDrive e2 configurations for dev/staging/prod
✅ **Environment Variables**: Added bucket name environment variables
✅ **Environment Configs**: Updated Rails environments to use appropriate storage

## File Changes Summary

### Modified Files:
1. `Gemfile` - Added aws-sdk-s3 gem
2. `config/storage.yml` - Added idrive_development, idrive_staging, idrive_production services
3. `config/environments/development.rb` - Kept local storage (with instructions to switch)
4. `config/environments/staging.rb` - Configured to use idrive_staging
5. `config/environments/production.rb` - Configured to use idrive_production
6. `.env` - Added bucket name environment variables

### New Files:
1. `IDRIVE_STORAGE_SETUP.md` - Comprehensive setup guide

## Current Configuration

| Environment | Storage Service | Bucket Name |
|-------------|----------------|-------------|
| Development | local (disk) | N/A |
| Staging | idrive_staging | guide-staging |
| Production | idrive_production | guide-production |
| Test | test (tmp) | N/A |

**Note**: Development uses local disk by default for faster iteration. You can switch to `idrive_development` when testing S3 integration.

## Next Steps

### 1. Create Buckets in iDrive e2 Dashboard

Log in to https://www.idrive.com/object-storage-e2/ and create three buckets in **us-southwest-1** region:

- `guide-development`
- `guide-staging`
- `guide-production`

### 2. Configure CORS (Optional but Recommended)

For each bucket, add this CORS policy:

```json
{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
```

Replace `"*"` in AllowedOrigins with your actual domain in production.

### 3. Test the Integration

#### Option A: Test in Rails Console

```bash
bin/rails console
```

```ruby
# Create a test file
file = StringIO.new("Hello, iDrive!")
file.original_filename = "test.txt"

# Upload
blob = ActiveStorage::Blob.create_and_upload!(
  io: file,
  filename: "test.txt",
  content_type: "text/plain"
)

# Verify URL
blob.url # Should return iDrive URL

# Clean up
blob.purge
```

#### Option B: Test with Your Application

If you have file upload functionality in your app (e.g., user avatars, tour images):

1. Temporarily switch development to use iDrive:
   ```ruby
   # config/environments/development.rb
   config.active_storage.service = :idrive_development
   ```

2. Restart server: `bin/dev`

3. Upload a file through your UI

4. Verify it appears in your iDrive e2 bucket

5. Switch back to local storage after testing

## Environment Variables Needed for Deployment

For staging and production deployments, ensure these environment variables are set:

```bash
# iDrive e2 Credentials (same for all environments)
IDRIVE_E2_ACCESS_KEY_ID=your_access_key_id
IDRIVE_E2_SECRET_ACCESS_KEY=your_secret_access_key

# Bucket Names
IDRIVE_E2_BUCKET_STAGING=guide-staging
IDRIVE_E2_BUCKET_PRODUCTION=guide-production
```

## Storage Service Configuration Details

### Key Settings:

- **Endpoint**: `https://s3.us-southwest-1.idrivee2.com`
- **Region**: `us-east-1` (required by AWS SDK, but not actually used by iDrive)
- **Force Path Style**: `true` (required for iDrive e2 compatibility)
- **Cache Control**:
  - Development/Staging: `private, max-age=31536000` (1 year)
  - Production: `public, max-age=31536000` (1 year, allows CDN caching)

## Troubleshooting

### "Cannot load `aws-sdk-s3`"
- Run `bundle install`
- Restart Rails server

### Connection/Authentication Errors
- Verify `IDRIVE_E2_ACCESS_KEY_ID` and `IDRIVE_E2_SECRET_ACCESS_KEY` are set correctly
- Check credentials haven't been rotated in iDrive dashboard

### Bucket Not Found (404)
- Ensure bucket exists in iDrive e2 dashboard
- Verify bucket name matches environment variable exactly
- Check bucket is in `us-southwest-1` region

### Permission Denied (403)
- Verify access key has proper permissions
- Check bucket policy allows read/write
- Ensure CORS is configured if uploading from browser

## Costs

iDrive e2 is significantly cheaper than AWS S3:

- **Storage**: ~$0.004/GB/month
- **Bandwidth**: First 3x of storage is free monthly
- **No fees for**: API requests, data transfer in, or DELETE requests

Example: For 100GB storage:
- Storage cost: $0.40/month
- Free bandwidth: 300GB/month
- Additional bandwidth: $0.01/GB

## Security Best Practices

1. ✅ Credentials stored in environment variables (not committed to Git)
2. ✅ Different buckets for each environment
3. ✅ Secure endpoints (HTTPS)
4. 🔒 **TODO**: Rotate credentials every 90 days
5. 🔒 **TODO**: Enable access logging in iDrive dashboard
6. 🔒 **TODO**: Update CORS origins to specific domains in production

## Additional Documentation

See `IDRIVE_STORAGE_SETUP.md` for comprehensive details on:
- Detailed configuration explanations
- Advanced troubleshooting
- Cost optimization strategies
- Security considerations
- Testing procedures

---

**Setup completed successfully!** 🎉

You're now ready to use iDrive e2 for file storage in staging and production environments.
