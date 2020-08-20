#!/bin/bash

source .env

docker build --network=host -t $USERNAME/$IMAGE:latest .

