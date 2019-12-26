#!/bin/bash

cd debian/tests/common/
python3 -m unittest test_async_eventlet.py
python3 -m unittest test_packet.py
