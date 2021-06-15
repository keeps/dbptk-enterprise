# CAS

### Configure available users

On `cas/` directory there are two files:

* users.txt - one user per line with the following syntax: `<username>::<password>`
* attribute-repository.json - a JSON file with a set of attributes per user

#### Pratical example

Let's add a new user to CAS that belongs to the administrators with username "test". To do so we need to edit the `users.txt` file and add the following line:

```txt
test::password12345
```

The next step is to edit `attribute-repository.json` file and add the following object:

Note: The object key is the name of the user. And all the three attributes are required. 

```json
"test": {
    "fullname": ["Test user"],
    "email": ["test-user@test.org"],
    "memberOf": ["administrators", "users"]
  }
```

For a user to be administrator the *memberOf* needs to have the values "administrators" and "users". If the user doesn't need to have administration capabilities the *memberOf* only needs to have the value "users".

If the CAS service is already running you need to restart the service.

```bash
# if running as a daemon
$ docker-compose down
$ docker-compose up -d

# if not hit CTRL+C and start the service again
$ docker-compose up
```