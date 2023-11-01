# 🖥️ 🔫 Machinegun.nvim 🖥️ 🔫

A plugin to help you customize your setup across different machines and users
with a single configuration. Machinegun.nvim makes it really easy to, for
example, have different color schemes on your laptop and remote computers or
when being root.

This doesn't add any functionality to neovim or functions you would frequently
use, but it makes life much easier. It was initially built for those that want
a single configuration that they can just share across all computers regardless
of operating system differences.

__How?__ We take an array of arbitrary lua tables defined per machine, and
potentially user, which are tagged with a machine ID.  Upon setup the table
gets built and stored in `require("machinegun").settings` and optionally a
global variable. Different configurations may be overlaid so that you don't
have to repeat yourself with shared settings.

## Contents

- [Installation](#installation)
- [Setting Up](#setting-up)
  - [Finding the machine ID](#finding-the-machine-id)
  - [Storing the machine ID](#storing-the-machine-id)
  - [Settings definitions](#defining-some-settings)
  - [Actually using the settings](#actually-using-the-settings)
- [Going global](#going-global)



## Installation
Installation with `lazy.nvim` just requires you to add an extra specification such
as:
```lua
return {
  "GCBallesteros/machinegun.nvim",
  config = true,
}
```

This will install the plugin and get you access to a few handy function but it
will do absolutely nothing, nil, zero, nada. This is a plugin to be used in
conjunction with your configuration files to access machine specific
parameters; what those are is up to you.

Once you have decided on them, you can add some `opts` that you can pass to the
`setup` function. They may look something like this:

```lua
-- using lazy.nvim
return {
  "GCBallesteros/machinegun.nvim",
  opts = {
    default = "macbook_air",  -- what is the source of default settings
    global = "MG",  -- optional name of the global variable to store the settings
    machines = {  -- table of machine names and ID pairs
      -- No need to have the full ID. A prefix match will be used
      macbook_air = "3hsd2a99",  
      work_laptop = "90qnj5ie",
      old_lenovo = "8204jdas",
    },
    -- The actual machine specific settings. A table with keys being one of the
    -- machines defined on `machines` above and that stores and arbitrary table
    -- which you can organize however best suits your needs
    settings = {  
      ["macbook_air"] = {
        colorscheme = "tokyonight",
        folders = { plugins="~/myplugins", projects="~/projects"},
      },
      ["root@macbook_air"] = { colorscheme = "catppuccin-latte" },
      ["old_lenovo"] = { colorscheme = "habamax" },
      ["work_laptop"]  = {
        colorscheme = "kanagawa",
        folders = { projects = "~/Work" }
      },
    }
  }
  config = true,  -- this is equivalent to doing require("machinegun").setup(opts)
}
```

Now as root on the Macbook Air your settings value for `colorscheme` would be
`catppuccin-latte` and otherwise `tokyonight`. However, if you opened up neovim
on the Lenovo you would get `habamax`. All with the same configuration that you
can now share easily and in a merge conflict way! Similarly the `folders`
values would be different depending on the machine.


## Setting up
... by way of an example.

Say we have two machines, _remote_ and _local_, and that we want to set them
up. At this point you have the minimal spec:

```lua
return {
  "GCBallesteros/machinegun.nvim",
  config = true,
}
```

### Finding the machine ID
The first thing that needs to be done is to get the machine ID. You can either
do it by running `vim.print(require("machinegun").get_machine_id())` if you
have installed machinegun.nvim. Alternatively you can run one of the
following commands on your terminal.

> [!NOTE]
> They don't output the actual machine UUID, but rather a hash of it, so that you
> can upload your configuration to a public space like Github or Gitlab without
> worries.

#### 🐧 Linux 🐧
```bash
cat /etc/machine-id | shasum -a 1 | cut -f 1 -d  " "
```

#### 🍎 Mac 🍎
```bash
ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}' | shasum -a 1 | cut -f 1 -d  " "
```

### Storing the machine ID
Now put the machine ID into the machinegun.nvim options. No need to write down
the whole retrieved ID because we do a prefix match. I personally use the first
8 characters.

```lua
return {
  "GCBallesteros/machinegun.nvim",
  opts = {
    machines = { local = "qwerty9876", remote = "12ab34cd"},
  },
  config = true,
}
```

### Defining some settings

Next, lets define some settings. Say we want to define a `colorscheme` setting
which is different for the _local_ and _remote_ computer. In addition to this,
when we are on the remote and are root we want yet another color scheme to avoid
silly mistakes. Finally, we want a work `folder` setting that depends on what
computer we are on.

```lua
  "GCBallesteros/machinegun.nvim",
  opts = {
    default = "remote",
    -- the values on the next line depend on your computer!
    machines = { local = "qwerty9876", remote = "12ab34cd"},
    settings = {
      ["local"] = { colorscheme = "tokyonight", folder = "~/projects" },
      ["remote"] = { colorscheme = "habamax", folder = "~/deployment" },
      ["root@remote"] = { colorscheme = "industry" },
    }
  },
  config = true,
```

The structure of the settings table that is set for each machine/user is
completely up to you. Here we just went with the simplest thing. We also told
machinegun.nvim to use the settings from _remote_ to be the default ones if a
value can't be found, see the next section for more details.

#### Option merging rules

A brief interlude on the option merging rules. The final settings table that
gets exposed by `require("machinegun").settings` is compiled by first looking
up the values for the current user AND machine, if it can't be found, then
check the value in the general settings of the machine. If both fail try with
the settings of the default option if one has been given.


### Actually using the settings!

We still haven't done anything... When we setup the plugin we will have the
correct settings tables under `require("machinegun").settings` or a global
variable (see section Going Global). Lets put them to use!

Suppose that somewhere on your configuration you have some place that currently
looks like:

```lua
vim.cmd.colorscheme("tokyonight")
```

but you would like it to be now machine dependent. Easy! First get the settings
and then just use the value provided.

```lua
local machine_settings = require("machinegun").settings

-- a few lines below
vim.cmd.colorscheme(machine_settings.colorscheme)
```

That's it! Depending on the actual machine and user the retrieved value will be
different.

This works fine in the context of the _single_ file configuration style but
what if you are using lazy.nvim for example. Then you have to make sure that
`GCBallesteros/machinegun.nvim` is added as a dependency to guarantee that it
gets loaded first so that the `require("machinegun")` call doesn't fail. In the
context of using [LazyVim](https://github.com/LazyVim/LazyVim) the example
above would look like:

```lua
return {
  {
    "LazyVim/LazyVim",
    dependencies = { "GCBallesters/machinegun.nvim" },
    opts = function(_, opts)
      local mg = require("machinegun").settings
      opts.colorscheme = mg.colorscheme
      return opts
    end,
  },
}
```

You might be thinking now, that the call to `require("machinegun")` is a bit
tedious but we've got you covered.

## 🌎 Going global 🌎

Having to `require("machinegun")` on every place you want to use machine
specific settings gets old fast. That is what the `global` option is for. It
will put the machine specific settings into a global variable with whatever
name you passed to the option so that you can access them from anywhere without
requiring the package all the time. Very convenient.

This turns the previous example, after having set the `global` option to `mg`
into:

```lua
return {
  {
    "LazyVim/LazyVim",
    dependencies = { "GCBallesters/machinegun.nvim" },
    opts = function(_, opts)
      opts.colorscheme = mg.colorscheme
      return opts
    end,
  },
}
```

> [!IMPORTANT]
> The global variable may shadow another global with the same name or be at at
> risk of getting showed. Be sure to pick a sensible name. The one name you
> definitely don't want to use is `_G` because that is reserved by lua. Another
> bad idea is to use anything of the form `MiniXXXX` as those are used by the
> mini family of plugins.

Okay, but I really don't want to add machinegun.nvim as a dependency.

## 🏎️ Living live on the fast line 🏎️

Talking about speed! Notice how you had to add machinegun.nvim as a dependency
to the config of every package if you are using something like
[packer](https://github.com/wbthomason/packer.nvim) or
[lazy.nvim](https://github.com/folke/lazy.nvim) to make sure that it loads
before?

Well, if your package manager supports it, you can set the priority of
machinegun.nvim to a high enough value such that you can _guarantee_ that it
will be loaded first. Combine this with the `global` option and now you can use
your machine specific settings from (almost) anywhere without any `requires` or
explicitly defined dependencies.

With lazy.nvim:

```lua
return {
  "GCBallesteros/machinegun.nvim",
  priority = 999999,
  --- all the other stuff
}
```

> [!NOTE] 
> By almost above I mean that there are no guarantees and you will need to
> experiment. For example I've tried it on the `LazyVim\LazyVim` example above
> and removing the dependency just broke stuff. For other plugins it did work.
> YMMV.

## Extra API

Machinegun.nvim uses the following function internally to figure out what
machine you are on and as what user. However, you may find them useful when
writing your config. They are:

- `require("machinegun").get_machine_id()`
- `require("machinegun").get_machine_name()`
- `require("machinegun").get_user()`
