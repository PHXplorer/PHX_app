[Back to main README](../../README.md#data-and-environment-variables)

# Authentication

To enable user authentication for the app, we use ShinyProxy authentication service.
Currently three methods are implemented:
- none
- simple
- ldap

We control which method to be used with `SHINYPROXY_AUTH_METHOD` environment variable.

It allows us to manage the visibility of the admin and production apps, based on the user access rights.
This is controlled with `AUTH_ADMIN_GROUP` and `AUTH_REGULAR_GROUP` environment variables, where the latter will have access only to the production application.

## Auth method: none

This method of authentication provides no restrictions based on user access rights.
All the applications will be accessible to all users.
Please note, that ShinyProxy generates an alpha-numeric sequence of random symbols to create a "username" for the users.
For this reason, the Telemetry app will not be able to show "anonymous" users - it will assume that all users are legit.

## Auth method: simple

This method uses a local _users.yml_ file, where all the users' credentials and their respective roles are pre-defined in a plain text format.
We recommend using this option as a temporary solution until there is a way to configure LDAP server.

## Auth method: ldap

> [!WARNING]
> Despite its name, `ldap` method is suitable for both
> OpenLDAP and Active Directory protocols.

### Connection details

This is the best and most secure way to provide user authentication in Health Equity Explorer.
ShinyProxy provides a set of configuration properties to let it connect to an LDAP or AD server.
Please refer to the [official documentation](https://www.shinyproxy.io/documentation/configuration/#ldap) - it also has examples.

We strive to have a single source of truth for various configurations.
That is why instead of writing these properties in the config file, we have those values defined in  [.env file](../../.env).
You still have the option to edit the application.yml file directly, but we recommend doing it via environment variables.

### Custom user lists

As described in the beginning of this section, it is most common to give users access to an application through a group that user belongs to.
However, we do acknowledge that in some organizations, adding users to respective groups might be a time-consuming process.
Therefore, to help you provide instant access to new users, we are using custom user lists.

When running any of the start scripts ([start.sh](../../scripts/start.sh) or [start.ps1](../../scripts/start.ps1)), the script will look for the existence of two plain text files inside the `shinyproxy` folder:
- `shinyproxy/admin_users.txt`
- `shinyproxy/regular_users.txt`
If not found, the script will create them with example values.

When a user logs in to ShinyProxy, the Proxy will decide which applications to show to the user based on (1) the group, and (2) the username - to check for its availability in any of the lists.

> ![NOTE]
> Please note that it is possible that a user exists in the LDAP list of users,
> but they don't belong to `AUTH_ADMIN_GROUP`, `AUTH_REGULAR_GROUP`,
> or in any of the user lists.
> In this case, if the user logs in, he/she won't see any applications.
