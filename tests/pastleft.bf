[Since out of bounds errors are in runtime, the code before the error occurs will still run until the error occurs]

++++++++++[>++++++<-]>+++++.    - still prints A error occurs after this instruction
> ++ [> +++++ <-]>.<            - print newline
<<<                             - causes error
++++++++++[>++++++<-]>+++++.    - next A won't print