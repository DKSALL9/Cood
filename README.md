# Cood
This Perl script performs a network scan for a list of words contained in a file. It tests each word by appending it to a provided base URL and making an HTTP request. The script supports concurrency, retries, and logs successes and failures. 

# Install
```
git clone https://github.com/DKSALL9/Cood.git
```

# Usage
```
    ____                       _ 
   / ___|   ___     ___     __| |
  | |      / _ \   / _ \   / _` |
  | |___  | (_) | | (_) | | (_| |
   \____|  \___/   \___/   \__,_|
   
Usage: perl script.pl [options] <filename> <url>
Options:
  --verbose             Enable detailed output
  --concurrency=n       Number of concurrent requests (default: 1)
  --retries=n           Number of retries for failed requests (default: 3)
  --help                Show this help message
```
