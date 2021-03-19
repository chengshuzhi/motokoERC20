import token_ERC20 from 'ic:canisters/token_ERC20';

token_ERC20.greet(window.prompt("Enter your name:")).then(greeting => {
  window.alert(greeting);
});
