# WalletTree

Implementations for the resolver for Wallettree.

For documentation of the Wallettree system, see (https://normal.gitbook.io/wallettree/).

To run unit tests, clone this repository, and run:

    $ npm install
    $ npm test

# npm package

This repo doubles as an npm package with the compiled JSON contracts

```js
import { Resolver } from '@wallettree/wallettree'
```

## Resolver.sol

Implementation of the Wallettree Resolver, the central contract used to look up resolvers for users. 

The Wallettree resolver is a single central contract that provides a mapping from personal identifiers such as email, phone, and social handles to profiles containing a list of wallets.