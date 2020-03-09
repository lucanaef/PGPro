---
layout: page
title: Donate
include_in_header: true
---

# Support PGPro

<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js"></script>
<script type="text/javascript" src="https://pgpro.app/assets/pay-now-button.js"></script>

<div style="display: inline-block">
  <a href="https://www.paypal.me/pgproapp">
    <img src="https://pgpro.app/assets/paypal-donate-button.png" alt="Donate with PayPal" style="width: 250px;"/>
  </a>
</div>
<div style="display: inline-block">
  <div class="blockchain-btn" data-address="3K6U863fR8TqTkE5AE1AzcxVFN7dhP6Ljc" data-shared="false">
    <div class="blockchain stage-begin">
        <img src="https://pgpro.app/assets/bitcoin-donate-button.png" alt="Donate with Bitcoin" style="width: 250px;"/>
    </div>
    <div class="blockchain stage-loading" style="text-align:center">
        <img src="https://blockchain.info/Resources/loading-large.gif"/>
    </div>
    <div class="blockchain stage-ready">
        <p align="center">Please Donate To Bitcoin Address: <b>[[address]]</b></p>
        <p align="center" class="qr-code"></p>
    </div>
    <div class="blockchain stage-paid">
        Donation of <b>[[value]] BTC</b> Received. Thank You.
    </div>
    <div class="blockchain stage-error">
        <font color="red">[[error]]</font>
    </div>
  </div>
</div>
