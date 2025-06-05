#!/bin/bash
set -e

# Set environment variables for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

ENDPOINT_URL="http://localhost:4566"
STACK_NAME="patient-management"

echo "🔧 Quick Fix and Deploy Process..."

echo "1. Please ensure you've made ONE of these changes to your LocalStack.java file:"
echo "   Option A: Change numberOfBrokerNodes(1) to numberOfBrokerNodes(2)"
echo "   Option B: Change maxAzs(2) to maxAzs(1) in createVpc() method"
echo ""

read -p "Have you made the MSK cluster fix? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please make the fix first, then run this script again."
    echo ""
    echo "📝 Quick fix options:"
    echo "Option A (Recommended): In createMskCluster() method:"
    echo "  Change: .numberOfBrokerNodes(1)"
    echo "  To:     .numberOfBrokerNodes(2)"
    echo ""
    echo "Option B: In createVpc() method:"
    echo "  Change: .maxAzs(2)"
    echo "  To:     .maxAzs(1)"
    exit 1
fi

echo "2. 🔨 Building and synthesizing CDK..."

# Assuming you're using Gradle (adjust if using Maven)
if [ -f "./gradlew" ]; then
    ./gradlew build
elif [ -f "./mvnw" ]; then
    ./mvnw compile
elif command -v gradle &> /dev/null; then
    gradle build
elif command -v mvn &> /dev/null; then
    mvn compile
else
    echo "⚠️ Please build your project manually first"
fi

# Run the main method to synthesize
echo "📦 Synthesizing CDK template..."
java -cp "target/classes:target/dependency/*" com.pm.stack.LocalStack 2>/dev/null || \
java -cp "build/classes/java/main:build/libs/*" com.pm.stack.LocalStack 2>/dev/null || \
echo "⚠️ Please run your CDK synthesis manually"

echo "3. 🚀 Deploying to LocalStack..."

# Verify LocalStack connection
aws --endpoint-url=$ENDPOINT_URL --region=us-east-1 sts get-caller-identity
echo "✅ LocalStack connection confirmed"

# Deploy the stack
aws --endpoint-url=$ENDPOINT_URL --region=us-east-1 cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file "./cdk.out/localstack.template.json" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

echo "🎉 Deployment completed successfully!"

echo "4. 🔍 Getting load balancer DNS name..."
aws --endpoint-url=$ENDPOINT_URL --region=us-east-1 elbv2 describe-load-balancers \
    --query "LoadBalancers[0].DNSName" --output text || echo "No load balancers found yet"

echo "✅ All done! Your patient management system should be running on LocalStack."