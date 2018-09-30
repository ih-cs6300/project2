data = dlmread('fullg.csv',',');
data2 = dlmread('full+push-sum.csv', ',');
figure(1);
clf;
h1 = semilogx(data(:,1), data(:,2), '*b-');
hold on;
h2 = semilogx(data2(:,1), data2(:, 2), '*r-');
xlabel('Number of Nodes', 'fontsize', 14);
ylabel('Time to Convergence (s)', 'fontsize', 14);
title('Full Topology: Time to Convergence');
legend('Gossip', 'Push-sum')
grid on;


set(gcf,'PaperUnits','inches');
set(gcf,'PaperOrientation','portrait');
set(gcf,'PaperSize',[6,6]);
set(gcf,'PaperPosition',[0,0,6,6]); 
print -dpng 'graph1.png' -r500

