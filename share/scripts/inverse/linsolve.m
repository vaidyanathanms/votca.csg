A = load('%NAME.gmc');
b = load('%NAME.imc');

b(:,2)=b(:,2)*0.0000001
x = b;
x(:,2)=0;

% x(25:end,2) = linsolve(A(25:end,25:end),b(25:end,2));
x(:,2) = linsolve(A,b(:,2));

save '%NAME.dpot.new' x '-ascii'
quit