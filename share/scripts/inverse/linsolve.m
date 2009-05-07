A = load('%NAME.gmc');
b = load('%NAME_noflags.imc');

b(:,2)=b(:,2);
x = b;
x(:,2)=0;

% x(25:end,2) = linsolve(A(25:end,25:end),b(25:end,2));
x(25:end,2) = -2*linsolve(A(25:end,25:end),b(25:end,2));

x(1:24,2)=x(25,2); % that's for the shift of beginning
x(1:end,2)=x(1:end,2)-x(end,2);

save '%NAME.dpot.matlab' x '-ascii'
quit
