#!/bin/bash
# Quick script to start/stop SSH test server

ACTION=${1:-start}

case "$ACTION" in
  start)
    echo "🚀 Starting SSH test server..."
    docker-compose -f docker-compose.test.yml up -d
    echo "⏳ Waiting for server to be ready..."
    sleep 5
    echo ""
    echo "✅ SSH server is running!"
    echo ""
    echo "Connection details:"
    echo "  Host: localhost"
    echo "  Port: 2222 (SSH), 2223 (SFTP)"
    echo "  Username: testuser"
    echo "  Password: testpass"
    echo ""
    echo "Test files are mounted at: ./test_data"
    echo ""
    echo "To view logs: docker-compose -f docker-compose.test.yml logs -f"
    ;;
  stop)
    echo "🛑 Stopping SSH test server..."
    docker-compose -f docker-compose.test.yml down
    echo "✅ Server stopped"
    ;;
  restart)
    echo "🔄 Restarting SSH test server..."
    docker-compose -f docker-compose.test.yml restart
    echo "✅ Server restarted"
    ;;
  logs)
    docker-compose -f docker-compose.test.yml logs -f
    ;;
  status)
    echo "📊 SSH server status:"
    docker-compose -f docker-compose.test.yml ps
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|logs|status}"
    exit 1
    ;;
esac
