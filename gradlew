#!/bin/sh

# Simple Gradle wrapper that delegates to system gradle or gradle-8.12
# Use Java 21 to avoid Java 25 compatibility issues with Kotlin

export JAVA_HOME=/usr/lib/jvm/java-21

# Try to find gradle in the environment
if command -v gradle &> /dev/null; then
    exec gradle "$@"
elif [ -x "/tmp/gradle-8.12/bin/gradle" ]; then
    exec /tmp/gradle-8.12/bin/gradle "$@"
elif [ -x "/tmp/gradle-8.10/bin/gradle" ]; then
    exec /tmp/gradle-8.10/bin/gradle "$@"
elif [ -x "/tmp/gradle-8.7/bin/gradle" ]; then
    exec /tmp/gradle-8.7/bin/gradle "$@"
else
    echo "ERROR: Could not find gradle installation"
    exit 1
fi
