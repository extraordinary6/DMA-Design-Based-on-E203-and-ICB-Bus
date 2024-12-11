% 读取文件
fid = fopen('data.txt', 'r');
data = textscan(fid, '%s');
fclose(fid);

% 解析数据
kernel = reshape(hex2dec(data{1}(1:27)), [3 3 3]); % 3个3x3的卷积核
features = reshape(hex2dec(data{1}(28:end)), [16 16 3]); % 3个16x16的特征图
kernel(:,:,1)=kernel(:,:,1)';
kernel(:,:,2)=kernel(:,:,2)';
kernel(:,:,3)=kernel(:,:,3)';
kernel(:,:,1)=flip(flip(kernel(:,:,1),1),2);
kernel(:,:,2)=flip(flip(kernel(:,:,2),1),2);
kernel(:,:,3)=flip(flip(kernel(:,:,3),1),2);
features(:,:,1)=features(:,:,1)';
features(:,:,2)=features(:,:,2)';
features(:,:,3)=features(:,:,3)';
% 执行卷积操作
output = zeros(14, 14, 3);
for i = 1:3
    output(:,:,i) = conv2(features(:,:,i), kernel(:,:,i), 'valid');
end

% 写入结果文件
fid = fopen('output_s.txt', 'w');
for k = 1:3
    for i = 1:14
        for j = 1:14
            fprintf(fid, '%d\n', output(i,j,k));
        end
    end
end
fclose(fid);
