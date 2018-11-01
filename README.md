<div>
  <h1 align="center">GraphUI</h1>
  <h3 align="center"><img src="data/icons/64/com.github.artemanufrij.graphui.svg"/><br>Graph Visualization based on <a href="https://www.graphviz.org">graphviz</a></h3>
  <p align="center">Designed for <a href="https://elementary.io">elementary OS</a></p>
</div>

[![Build Status](https://travis-ci.org/artemanufrij/graphui.svg?branch=master)](https://travis-ci.org/artemanufrij/graphui)

### Donate
<a href="https://www.paypal.me/ArtemAnufrij">PayPal</a> | <a href="https://liberapay.com/Artem/donate">LiberaPay</a> | <a href="https://www.patreon.com/ArtemAnufrij">Patreon</a>

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.artemanufrij.graphui">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter">
  </a>
</p>

<br/>

![screenshot](screenshots/Screenshot.png)

## Install from Github.

As first you need elementary SDK
```
sudo apt install elementary-sdk
```

Install dependencies
```
sudo apt install libgtksourceview-3.0-dev graphviz
```

Clone repository and change directory
```
git clone https://github.com/artemanufrij/graphui.git
cd graphui
```

Compile, install and start GraphUI on your system
```
meson build --prefix=/usr
cd build
sudo ninja install
com.github.artemanufrij.graphui
```
