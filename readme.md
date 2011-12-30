Capify Ec2
====================================================

capify-ec2 is used to generate capistrano namespaces using ec2 tags.

eg: If you have three servers on amazon's ec2.

    server-1 Tag: Role => "web"
    server-2 Tag: Role => "db"
    server-3 Tag: Roles => "web, db"

Installing

    gem install capify-ec2

In your deploy.rb:

```ruby
require "capify-ec2/capistrano"
ec2_roles :web
```

Will generate

```ruby
task :server-1 do
  role :web, {server-1 public dns fetched from Amazon}
end

task :server-3 do
  role :web, {server-3 public dns fetched from Amazon}
end

task :web do
  role :web, {server-1 public dns fetched from Amazon}
  role :web, {server-3 public dns fetched from Amazon}
end
```

Additionally

```ruby
require "capify-ec2/capistrano"
ec2_roles :db
```

Will generate

```ruby
task :server-2 do
  role :db, {server-2 public dns fetched from Amazon}
end

task :server-3 do
  role :db, {server-3 public dns fetched from Amazon}
end

task :db do
  role :db, {server-2 public dns fetched from Amazon}
  role :db, {server-3 public dns fetched from Amazon}
end
```

Running

```bash
cap web date
```

will run the date command on all server's tagged with the web role


Running

```bash
cap ec2:status
```

will list the currently running servers and their associated details
(public dns, instance id, roles etc)


Running

```bash
cap ec2:ssh
```

will show a list of all running instances and let you enter the
server # to ssh into, using the user and port specified in your configuration.


Running

```bash
cap ec2:ssh -s ec2roles=web,db
```

will show a list of running instances __filtered by roles__, and let you enter the
server # to ssh into, using the user and port specified in your configuration.

More options
====================================================

```ruby
ec2_roles {:name=>"web", :options=>{:cron=>"server-1"}}
```

Will generate

```ruby
task :server-1 do
  role :web, {server-1 public dns fetched from Amazon}, :cron=>true
end

task :server-3 do
  role :web, {server-3 public dns fetched from Amazon}
end

task :web do
  role :web, {server-1 public dns fetched from Amazon}, :cron=>true
  role :web, {server-3 public dns fetched from Amazon}
end
```

Which is cool if you want a task like this in deploy.rb

```ruby
task :update_cron => :web, :only=>{:cron} do
  Do something to a server with cron on it
end

ec2_roles :name=>:web, :options=>{ :default => true }
```

Will make :web the default role so you can just type 'cap deploy'.
Multiple roles can be defaults so:

```ruby
ec2_roles :name=>:web, :options=>{ :default => true }
ec2_roles :name=>:app, :options=>{ :default => true }
```

would be the equivalent of 'cap app web deploy'

Ec2 config
====================================================

This gem requires 'config/ec2.yml' in your project.
The yml file needs to look something like this:

```yml
:aws_access_key_id: "YOUR ACCESS KEY"
:aws_secret_access_key: "YOUR SECRET"
:aws_params:
  :region: 'eu-west-1'
:project_tag: "YOUR APP NAME"
```

The :aws_params are optional.
The :project_tag parameter is optional. It will limit any commands to
running against those instances with a "Project" tag set to the value "YOUR APP NAME".

## Development

Source hosted at [GitHub](http://github.com/forward/capify-ec2).
Report Issues/Feature requests on [GitHub Issues](http://github.com/forward/capify-ec2/issues).

### Note on Patches/Pull Requests

 * Fork the project.
 * Make your feature addition or bug fix.
 * Add tests for it. This is important so I don't break it in a
   future version unintentionally.
 * Commit, do not mess with rakefile, version, or history.
   (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
 * Send me a pull request. Bonus points for topic branches.

### Modifications, by Alex Simenduev (see changelog)

## Copyright

Copyright (c) 2011 Forward. See [LICENSE](https://github.com/forward/capify-ec2/blob/master/LICENSE) for details.
