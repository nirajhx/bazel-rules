#!/bin/sh

if [ "$ENABLE_JAVA_DEBUG" ]; then
	export PATH="/opt/bin/debug:$PATH"
else
	export PATH="/opt/bin:$PATH"
fi

# Link cacerts if externals are there (this is done in alpine automaticly but debian openjdk is missing cacerts-java package which includes that link)
# Distinguish between Java8 and Java11 installation based on existing installation directory
if [ -f "/etc/ssl/certs/java/cacerts" ] && [ -d "/usr/local/openjdk-11/" ]; then
	ln -sf /etc/ssl/certs/java/cacerts /usr/local/openjdk-11/lib/security/cacerts
elif [ -f "/etc/ssl/certs/java/cacerts" ] && [ -d "/usr/local/openjdk-8/" ]; then
	ln -sf /etc/ssl/certs/java/cacerts /usr/local/openjdk-8/lib/security/cacerts
fi

exec "$@"
