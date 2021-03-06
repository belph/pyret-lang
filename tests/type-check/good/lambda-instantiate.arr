tru  = lam<A>(t :: A): lam<B>(f :: B): t;;
fals = lam<A>(t :: A): lam<B>(f :: B): f;;
test = lam<A>(cond :: (A -> (A -> A))): lam(consq :: A): lam(altern :: A): cond(consq)(altern);;;

# tru-same   = lam<A>(t :: A) tru<A>(t)<A>;
# false-same = lam<A>(t :: A) tru<A>(t)<A>;

tru-number = tru<Number>
a = tru(5)
b = tru-number(5)
b-number = b<Number>
c :: Number = b-number(6)

fals-string = fals<String>
d = fals-string("asdf")
d-number = d<Number>
e :: Number = d-number(6)

# test(tru-same<Number>)(5)(6)
