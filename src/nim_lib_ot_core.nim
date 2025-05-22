## Operational Transformation library for Nim
##
## This library provides operational transformation functionality
## for real-time collaborative editing applications.

# Re-export main modules
import nim_lib_ot_core/[types, operations, transform, client, server, protocol]
export types, operations, transform, client, server, protocol

when isMainModule:
  echo "Nim Operational Transformation Core Library v0.1.0"