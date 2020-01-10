---
layout: page
title: Donate
include_in_header: true
---

<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js"></script>
<script type="text/javascript" src="https://blockchain.info/Resources/js/pay-now-button.js"></script>

<a href="https://www.paypal.me/pgproapp/5">
  <img src="https://pgpro.app/assets/paypal-donate-button.png" alt="Donate with PayPal" />
</a>
<div style="display: inline-block">
  <div class="blockchain-btn" data-address="3K6U863fR8TqTkE5AE1AzcxVFN7dhP6Ljc" data-shared="false">
    <div class="blockchain stage-begin">
        <img src="https://pgpro.app/assets/bitcoin-donate-button.png"/>
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
