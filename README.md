# sysreport

Quick health check scripts I use when troubleshooting someone's machine. Prints system info, CPU/memory, disk space, network status, top memory users, failed services and recent errors.

## Linux

```
chmod +x sysreport.sh
./sysreport.sh
./sysreport.sh -o report.txt     # save a copy
./sysreport.sh -w 80             # warn at 80% disk instead of 90
```

Run with sudo to see all journal errors.

## Windows

```
powershell -ExecutionPolicy Bypass -File .\sysreport.ps1
powershell -ExecutionPolicy Bypass -File .\sysreport.ps1 -Out report.txt -Warn 80
```
