
## Monitor S3 Buckets for Public Access Changes

This guide shows you how to monitor your Amazon S3 buckets for changes in public access using AWS CloudTrail, AWS CloudWatch, and CloudWatch Alarms.

### 1. Enable AWS CloudTrail

AWS CloudTrail allows you to monitor your AWS deployments. CloudTrail logs all bucket-level actions by default.

- Navigate to the AWS Management Console, select CloudTrail service.
- Click on "Create trail."
- Name your trail and specify the S3 bucket where logs will be stored.
- Apply the trail to all regions, if needed.
- Click on "Create."

### 2. Create a CloudWatch Log Group and Log Stream

AWS CloudWatch is a monitoring service for AWS resources and applications. It can be used with CloudTrail to monitor changes in S3 bucket permissions.

- Navigate to AWS CloudWatch in the AWS Management Console.
- Click on "Logs" in the sidebar.
- Click "Create log group" and name your new log group.
- After creating the log group, click on "Create log stream" and name your new log stream.

### 3. Create a CloudTrail to CloudWatch Logs Subscription

This step ensures that your CloudTrail logs are automatically sent to CloudWatch.

- Return to CloudTrail and select your trail.
- Under the "CloudWatch Logs" section, click on "Configure."
- Select the CloudWatch log group you created, create a new IAM role for CloudTrail to use.
- Click on "Continue."

### 4. Create Metric Filters

Metric filters define the patterns to look for in log data as it is sent to CloudWatch.

- Return to CloudWatch and select your log group.
- Click on "Create Metric Filter."
- In the filter pattern field, input patterns to match changes in your S3 bucket permissions, such as `{ ($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) }`.
- Define a filter name and click on "Assign Metric," where you will specify the metric details.

### 5. Set up CloudWatch Alarms

CloudWatch Alarms notify you when certain thresholds are hit or anomalies are detected by the metric filters.

- In the CloudWatch console, click on "Alarms" then "Create alarm."
- Select the custom metric you created via the filter.
- Define the conditions for your alarm. For instance, you might want to set the threshold type to "Static" and whenever the metric is "Greater/Equal" than 1, it triggers the alarm.
- Set up actions for when the alarm state is triggered, such as sending a notification through Amazon SNS.
- Name and describe your alarm.
- Click on "Create Alarm."

By following these steps, you can monitor changes in public access to your S3 buckets. When such a change is detected, CloudTrail records the action, CloudWatch filters the log data for these actions, and a CloudWatch Alarm is triggered to notify you.

### Making an S3 Bucket Public

The API call that can make an S3 bucket public is `PutBucketAcl`. This operation sets the Access Control List (ACL) of an S3 bucket. When the ACL is set to allow public read or write access, the bucket becomes public.

Please note that setting a bucket to public can expose your data to the world, and it's generally not a recommended practice. AWS advises that you manage access using IAM policies and bucket policies instead of ACLs.