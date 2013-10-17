Trac on Heroku
==============

First, we'll create an empty top-level directory for our project:

    $ mkdir hellotrac
    $ cd hellotrac

### Specify dependencies with Pip

Heroku recognizes Python applications by the existence of a `requirements.txt` file in the root of a repository.

`requirements.txt`

    trac
    psycopg2

### Store your app in Git

Next, we'll create a new git repository and save our changes:

    $ git init
    $ git add requirements.txt
    $ git commit -m "requirements.txt"

### Deploy your application to Heroku

The next step is to push this repository to Heroku. First, we have to get a place to push to from Heroku. We can do this with the `heroku create` command:

    $ heroku create

This automatically added the Heroku remote for our app to our repository. Now we can do a simple git push to deploy our application:

    $ git push heroku master

### Create database

Heroku Postgres can be attached to a Heroku application via the CLI:

    $ heroku addons:add heroku-postgresql:dev

Heroku recommends using the `DATABASE_URL` config variable to store the location of your primary database. In single-database setups your new database will have already been assigned a `HEROKU_POSTGRESQL_COLOR_URL` config variable but must be promoted to have its location set in the `DATABASE_URL`:

    $ heroku pg:promote HEROKU_POSTGRESQL_COLOR_URL

### Create Trac environment

Now that we have a prepared Heroku application to work with, we'll create our Trac environment:

    $ foreman run trac-admin env initenv <projectname> `heroku config:get DATABASE_URL`

### Protect database string

By default, Trac stores our PostgreSQL database string in `env/conf/trac.ini`. However, this flies in the face of the Heroku convention of keeping all private or environment-specific data in config variables.

The best method I've found for reconciling these two different practices is to take advantage of Heroku's [.profile script](https://devcenter.heroku.com/articles/dynos#startup) feature and Trac's [configuration inheritance](http://trac.edgewall.org/wiki/TracIni#inherit-section) feature.

First, we remove the `database` line from our `env/conf/trac.ini` file, so that it stays out of version control altogether:

    $ sed -i '' '/database = /d' env/conf/trac.ini

Then, we can commit our Trac environemnt to the git repository:

    $ git add env
    $ git commit -m "env"

If a script named `.profile` exists in the root of the repository, Heroku will run it during every dyno startup. Thus, we can use a very simple bash script to write the database string to a `env/conf/db.ini` file.

`.profile`

    #!/usr/bin/env bash
    echo [trac] > env/conf/db.ini
    echo database = $DATABASE_URL >> env/conf/db.ini

Now, to let Trac know to inherit from the `env/conf/db.ini` file:

    $ echo [inherit] >> env/conf/trac.ini
    $ echo file = db.ini >> env/conf/trac.ini
    $ echo >> env/conf/trac.ini

Just in case the `db.ini` file somehow ends up on our local machine, we want to make sure we don't check it into version control:

    $ echo env/conf/db.ini >> .gitignore

As always, we can commit these changes to the git repository:

    $ git add .profile
    $ git add .gitignore
    $ git add env/conf/trac.ini
    $ git commit -m "db"

### Declare process with Procfile

Processes to be run on Heroku are defined in a simple text file, `Procfile`, that lives in the root of a repository.

`Procfile`

    web: tracd -s -p $PORT env

Push this change to Heroku:

    $ git add Procfile
    $ git commit -m "Procfile"
    $ git push heroku master

### Launch a web dyno

Let's ensure we have one dyno running the `web` process type:

    $ heroku ps:scale web=1

We can now visit the app in our browser:

    $ heroku open

### Next steps

* [Account Manager Plugin](https://github.com/drewbug/heroku-trac/wiki/Account-Manager-Plugin)
