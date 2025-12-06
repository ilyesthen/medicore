# Protocol Buffers (Protobuf) Definitions

This directory contains `.proto` files that define the gRPC service contracts between the Flutter app and Go server.

## Generating Code

### For Go (Server):
```bash
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/*.proto
```

### For Dart (Flutter Client):
```bash
protoc --dart_out=grpc:lib/src/generated -Iproto proto/*.proto
```

## Example Proto File Structure

```protobuf
syntax = "proto3";

package medicore;
option go_package = "medicore-server/proto";

service PatientService {
  rpc CreatePatient (PatientRequest) returns (PatientResponse);
  rpc GetPatient (GetPatientRequest) returns (PatientResponse);
}

message PatientRequest {
  string name = 1;
  int32 age = 2;
  string phone = 3;
}

message PatientResponse {
  int32 id = 1;
  string name = 2;
  int32 age = 3;
  string phone = 4;
}

message GetPatientRequest {
  int32 id = 1;
}
```

Add your `.proto` files here as you build features.
