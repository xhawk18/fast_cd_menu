## What's this?

"fast_cd_menu" is a bash script to support command "c" in bash to show cd history as menu.

![screen snapshot](./screen0.png)

## Installation

(Bash 3.0 or higher is required)

To install or update fast_cd_menu, you can use the install script with curl

```bash
curl -o- https://raw.githubusercontent.com/xhawk18/fast_cd_menu/master/install.sh | bash
```

or wget
```bash
wget -qO- https://raw.githubusercontent.com/xhawk18/fast_cd_menu/master/install.sh | bash
```

The script installs fast_cd_menu in \~/.fast_cd and adds the source line to your profile (\~/.bash_profile, \~/.profile, or \~/.bashrc).

```bash
source "$HOME/.fast_cd/fast_cd_menu.sh"
```

## Usage

After installed, **re-open** the bash console and **cd** to some folders firstly, and then you can try the super command **c**. For example --

* show a menu of cd history

```bash
c
```

* go to 2nd folder in the cd history

```bash
c 2
```

* go to the folder which name contains string test,
where "name" is the folder's name, not full path.

```bash
c test
```
