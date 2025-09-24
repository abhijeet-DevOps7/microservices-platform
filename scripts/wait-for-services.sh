#!/bin/bash
# Wait for services to be ready

echo "🔄 Waiting for services to be ready..."

# Function to wait for a service
wait_for_service() {
    local service=$1
    local port=$2
    local timeout=${3:-120}
    local count=0
    
    echo "⏳ Waiting for $service on port $port..."
    
    while ! nc -z localhost $port; do
        if [ $count -ge $timeout ]; then
            echo "❌ Timeout waiting for $service"
            exit 1
        fi
        count=$((count + 1))
        sleep 1
    done
    
    echo "✅ $service is ready on port $port"
}

# Function to wait for HTTP service
wait_for_http() {
    local service=$1
    local url=$2
    local timeout=${3:-120}
    local count=0
    
    echo "⏳ Waiting for $service at $url..."
    
    while ! curl -f -s $url > /dev/null 2>&1; do
        if [ $count -ge $timeout ]; then
            echo "❌ Timeout waiting for $service"
            exit 1
        fi
        count=$((count + 1))
        sleep 1
    done
    
    echo "✅ $service is ready at $url"
}

echo "🚀 Starting service readiness checks..."

# Wait for infrastructure services
wait_for_service "PostgreSQL" 5432
wait_for_service "MongoDB" 27017
wait_for_service "Redis" 6379
wait_for_service "RabbitMQ" 5672
wait_for_service "Kafka" 9092
wait_for_service "Elasticsearch" 9200

# Wait for HTTP services
wait_for_http "PostgreSQL" "http://localhost:5432"
wait_for_http "RabbitMQ Management" "http://localhost:15672"
wait_for_http "Elasticsearch" "http://localhost:9200"

# Wait for microservices
echo "⏳ Waiting for microservices..."
services=(
    "user-service:8001"
    "product-service:8002"
    "order-service:8003"
    "payment-service:8004"
    "inventory-service:8005"
    "notification-service:8006"
    "analytics-service:8007"
    "recommendation-service:8008"
)

for service in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service"
    wait_for_http "$name" "http://localhost:$port/health"
done

# Wait for API Gateway
wait_for_http "Kong Gateway" "http://localhost:8000"

# Wait for monitoring services
wait_for_http "Prometheus" "http://localhost:9090/-/healthy"
wait_for_http "Grafana" "http://localhost:3000/api/health"
wait_for_http "Jaeger" "http://localhost:16686"

echo ""
echo "🎉 All services are ready!"
echo ""
echo "📊 Service URLs:"
echo "  • API Gateway: http://localhost:8000"
echo "  • User Service: http://localhost:8001"
echo "  • Product Service: http://localhost:8002"
echo "  • Order Service: http://localhost:8003"
echo "  • Payment Service: http://localhost:8004"
echo "  • Inventory Service: http://localhost:8005"
echo "  • Notification Service: http://localhost:8006"
echo "  • Analytics Service: http://localhost:8007"
echo "  • Recommendation Service: http://localhost:8008"
echo ""
echo "🔍 Monitoring URLs:"
echo "  • Prometheus: http://localhost:9090"
echo "  • Grafana: http://localhost:3000 (admin/admin123)"
echo "  • Jaeger: http://localhost:16686"
echo "  • RabbitMQ Management: http://localhost:15672 (guest/guest)"
echo ""
echo "🗄️ Database URLs:"
echo "  • PostgreSQL: localhost:5432"
echo "  • MongoDB: localhost:27017"
echo "  • Redis: localhost:6379"
echo "  • Elasticsearch: http://localhost:9200"
echo ""
echo "🚀 Platform is ready for development!"