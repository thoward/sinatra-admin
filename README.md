sinatra-admin
=============

A template for a Sinatra Admin app

## Running Locally

1. Install dependencies w/ bundler

```
bundle install
```

2. Configure environment (if using Github Auth)

```
export GITHUB_KEY=...
export GITHUB_SECRET=...
export GITHUB_TEAMID=...
```

3. Run rackup
```
rackup
```

NOTE: You will need to register an application under your Github account to get the key/secret needed for this. Since that requires a domain name, 
I generally create a dev application in Github to dev.domain.com and then map 127.0.0.1 to dev.domain.com in my /etc/hosts . Then when it's running, 
navigate to dev.domain.com:9292 to see the app. 

