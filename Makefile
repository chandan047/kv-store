#
# Copyright 2015 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

HOST_SYSTEM = $(shell uname | cut -f 1 -d_)
SYSTEM ?= $(HOST_SYSTEM)
CXX = g++
CPPFLAGS += `pkg-config --cflags protobuf grpc`
CXXFLAGS += -std=c++11
ifeq ($(SYSTEM),Darwin)
LDFLAGS += -L/usr/local/lib `pkg-config --libs protobuf grpc++`\
           -pthread\
           -lgrpc++_reflection\
           -ldl
else
LDFLAGS += -L/usr/local/lib `pkg-config --libs protobuf grpc++`\
           -pthread\
           -Wl,--no-as-needed -lgrpc++_reflection -Wl,--as-needed\
           -ldl
endif
PROTOC = protoc
GRPC_CPP_PLUGIN = grpc_cpp_plugin
GRPC_CPP_PLUGIN_PATH ?= `which $(GRPC_CPP_PLUGIN)`

PROTOS_PATH = ./protos

vpath %.proto $(PROTOS_PATH)

all: server client userprogram

server: kvmsg.pb.o kvmsg.grpc.pb.o server.o
	$(CXX) $^ $(LDFLAGS) -o $@

client: kvmsg.pb.o kvmsg.grpc.pb.o client.o client.h
	$(CXX) $^ $(LDFLAGS) -o $@
userprogram: userprogram.o
	$(CXX) $^ $(LDFLAGS) -o $@

.PRECIOUS: %.grpc.pb.cc
%.grpc.pb.cc: %.proto
	$(PROTOC) -I $(PROTOS_PATH) --grpc_out=. --plugin=protoc-gen-grpc=$(GRPC_CPP_PLUGIN_PATH) $<

.PRECIOUS: %.pb.cc
%.pb.cc: %.proto
	$(PROTOC) -I $(PROTOS_PATH) --cpp_out=. $<

clean:
	rm -f *.o *.pb.cc *.pb.h server client userprogram
