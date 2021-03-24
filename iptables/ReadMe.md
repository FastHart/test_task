Считаю, что внесение IP адресов напрямую в iptables - это bad practice.  
Вместо прямого внесения IP будем использовать ipset.  
К сожалению это противоречит заданию, где в условиях указано, что IP должны покаыываться в выводе `iptables -L`, но тем не менее, чем хуже `ipset list`?

00-iptables.conf  с ноликами в начале, что бы применился первым

```
usage: 
ipset restore  <ipset.txt
iptables-restore <iptables.txt
ipset list
```
