See the [README](http://rails.documentation.codyrobbins.com/2.3.18/) of the Ruby on Rails 2.3.18 Documentation for more info.

# Running the OpenStreetView

Step-to-step tested in Ubuntu 12.04.4 LTS "Precise".

## System dependencies
```bash
sudo apt-get install build-essential git ruby ruby-dev libmysqlclient-dev mysql-server imagemagick
```

## Rails
```bash
sudo gem install -v=2.3.18 rails
```
This command take a few seconds to start showing output.

## OSV + auth
```bash
sudo mkdir -p /srv/http
cd !$

# $MYGITDIR example: /home/USER/Git/
sudo ln -s $MYGITDIR/OpenStreetView openstreetview
cd $MYGITDIR/OpenStreetView

git clone git://github.com/technoweenie/restful-authentication.git vendor/plugins/restful_authentication
```

## Ruby dependencies
```bash
sudo rake gems:install
sudo gem install mysql
```

## Database creation
```bash
cat << EOF | mysql -h localhost -u root -p
CREATE DATABASE openstreetview_org_development;
GRANT ALL ON openstreetview_org_development.* TO DB_USER@localhost IDENTIFIED BY 'DB_PASS';
EOF

# change the connection config
sed -i 's@/tmp/mysql.sock@/var/run/mysqld/mysqld.sock@' config/database.yml
sed -i 's@username: root@username: DB_USER@' config/database.yml
sed -i 's@password:@password: DB_PASS@' config/database.yml

rake db:migrate RAILS_ENV="development"
```

## Web start
```bash
./script/server -e development
```

1. Access `http://localhost:3000` → [Go!](http://localhost:3000)
1. Create an account
1. Accesse the log: `less -R log/development.log`
1. Get a activation link that looks with <tt>http://localhost:300<b>2</b>/activate/b082238ef819c39136d71a3558821b0cd5577b10</tt>
1. But change the port — <tt>http://localhost:300<b>0</b>/activate/b082238ef819c39136d71a3558821b0cd5577b10</tt> — before of access it
1. You can to access your account now!

Remember that you need to run `script/tools/processor.rb` manually and **keep it running**.

