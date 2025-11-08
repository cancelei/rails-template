# iDrive e2 Storage Setup Guide

This application uses iDrive e2 (an S3-compatible object storage service) for storing uploaded files via Active Storage.

## Overview

- **Development**: Uses local disk storage by default (faster iteration)
- **Staging**: Uses iDrive e2 with dedicated staging bucket
- **Production**: Uses iDrive e2 with dedicated production bucket

## Prerequisites

1. **iDrive e2 Account**: Sign up at https://www.idrive.com/object-storage-e2/
2. **Access Credentials**: Obtain your Access Key ID and Secret Access Key from the iDrive e2 dashboard

## Configuration

### 1. Environment Variables

The following environment variables must be set:

```bash
# iDrive e2 Credentials
IDRIVE_E2_ACCESS_KEY_ID=your_access_key_id
IDRIVE_E2_SECRET_ACCESS_KEY=your_secret_access_key

# Bucket Names (one bucket per environment)
IDRIVE_E2_BUCKET_DEVELOPMENT=guide-development
IDRIVE_E2_BUCKET_STAGING=guide-staging
IDRIVE_E2_BUCKET_PRODUCTION=guide-production
```

These are already configured in your `.env` file for development.

### 2. Create Buckets in iDrive e2

You need to create separate buckets for each environment:

1. Log in to your iDrive e2 dashboard
2. Navigate to the "Buckets" section
3. Create the following buckets in the **us-southwest-1** region:
   - `guide-development`
   - `guide-staging`
   - `guide-production`

4. Set appropriate permissions:
   - **Development/Staging**: Can be private
   - **Production**: Consider enabling public read access if you need direct file URLs

### 3. Bucket Permissions

For each bucket, configure the following CORS policy to allow uploads from your application:

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

**Note**: In production, replace `"*"` in `AllowedOrigins` with your actual domain(s).

## Testing the Setup

### Test in Development (using iDrive)

To test the iDrive integration in development:

1. Update `config/environments/development.rb`:
   ```ruby
   config.active_storage.service = :idrive_development
   ```

2. Restart your Rails server

3. Test file upload functionality

### Test in Rails Console

```ruby
# Create a test file
file = StringIO.new("Hello, iDrive!")
file.original_filename = "test.txt"

# Upload to Active Storage
blob = ActiveStorage::Blob.create_and_upload!(
  io: file,
  filename: "test.txt",
  content_type: "text/plain"
)

# Get the URL
blob.url
# => "https://guide-development.s3.us-southwest-1.idrivee2.com/..."

# Clean up
blob.purge
```

## Production Deployment

### Environment Variables for Production

Ensure your production environment has these variables set:

```bash
IDRIVE_E2_ACCESS_KEY_ID=your_production_access_key
IDRIVE_E2_SECRET_ACCESS_KEY=your_production_secret_key
IDRIVE_E2_BUCKET_PRODUCTION=guide-production
```

### Verification Checklist

- [ ] Buckets created in iDrive e2
- [ ] CORS policy configured
- [ ] Environment variables set in production
- [ ] File upload tested successfully
- [ ] File deletion tested successfully
- [ ] Direct URL access works as expected

## Switching Between Storage Services

### Use Local Storage (Development Default)
```ruby
config.active_storage.service = :local
```

### Use iDrive Development
```ruby
config.active_storage.service = :idrive_development
```

### Use iDrive Staging
```ruby
config.active_storage.service = :idrive_staging
```

### Use iDrive Production
```ruby
config.active_storage.service = :idrive_production
```

## Cost Optimization

iDrive e2 pricing is based on storage used and data transfer:

- **Storage**: ~$0.004/GB/month (significantly cheaper than AWS S3)
- **Download**: First 3x of storage is free
- **Upload**: Free

### Best Practices:
1. Use appropriate cache control headers (configured in `storage.yml`)
2. Delete unused files regularly
3. Use image processing to reduce file sizes
4. Consider lifecycle policies for old files

## Troubleshooting

### Connection Issues

If you get connection errors:

1. Verify credentials are correct
2. Check bucket name matches exactly
3. Ensure endpoint URL is correct: `https://s3.us-southwest-1.idrivee2.com`
4. Verify `force_path_style: true` is set in `storage.yml`

### Permission Errors

If you get 403 Forbidden errors:

1. Verify the access key has proper permissions
2. Check bucket policy allows the necessary operations
3. Ensure CORS policy is correctly configured

### File Not Found (404)

If uploaded files return 404:

1. Verify the file was actually uploaded
2. Check the bucket name in the URL
3. Verify bucket exists and is accessible
4. Check if the bucket requires authentication for reads

## Additional Resources

- [iDrive e2 Documentation](https://www.idrive.com/object-storage-e2/docs)
- [Rails Active Storage Guide](https://guides.rubyonrails.org/active_storage_overview.html)
- [AWS SDK for Ruby - S3](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3.html)

## Security Notes

1. **Never commit credentials to Git**
   - Credentials are in `.env` which is gitignored
   - Use environment variables in production

2. **Rotate credentials periodically**
   - Generate new access keys regularly
   - Update environment variables accordingly

3. **Use least privilege principle**
   - Grant only necessary permissions to access keys
   - Consider separate keys for staging and production

4. **Monitor access logs**
   - Enable logging in iDrive e2 dashboard
   - Review for unusual activity
