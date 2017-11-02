# Admin Panel

The admin panel is available at `/admin`, you must be flagged as an admin to view anything in it. You can sign in via the regular sign in form or the admin specific form. You can make your user an admin by doing the following in an IEx console:

```elixir
user = Data.Repo.get_by(Data.User, name: "yourname")
user |> Data.User.changeset(%{flags: ["admin"]}) |> Data.Repo.update()
```

## Dashboard

![Admin Dashboard](/images/admin-dashboard.png)

The dashboard has a few counters for users, items, zones, and rooms. It also has a panel showing the currently connected users, which you can teleport your user to.
