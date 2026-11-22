#!/usr/bin/env python3
"""Fail a build if Google OAuth settings are missing or callbacks cannot return."""
import plistlib
import sys
from pathlib import Path

def validate(info, service):
    client = info.get('GIDClientID', '')
    if not isinstance(client, str) or not client.endswith('.apps.googleusercontent.com') or any(c.isspace() for c in client) or len(client) <= len('.apps.googleusercontent.com'):
        raise ValueError('Missing or invalid GIDClientID in app Info.plist')
    reverse = '.'.join(reversed(client.split('.')))
    schemes = [s for item in info.get('CFBundleURLTypes', []) for s in item.get('CFBundleURLSchemes', [])]
    if reverse not in schemes:
        raise ValueError('Google callback URL scheme is missing from app Info.plist')
    if service.get('CLIENT_ID') != client or service.get('REVERSED_CLIENT_ID') != reverse:
        raise ValueError('GoogleService-Info.plist OAuth IDs are missing or inconsistent')

if __name__ == '__main__':
    try:
        validate(*(plistlib.loads(Path(p).read_bytes()) for p in sys.argv[1:]))
    except (ValueError, OSError, TypeError) as error:
        sys.exit('error: Google Sign-In configuration: ' + str(error))
    print('Google Sign-In configuration and callback scheme verified')
