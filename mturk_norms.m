% Read in mturk norming data and weight based on rank
% Result should be the three strongest associated verbs for each seqeuence

% Walter Reilly
% Lasat update:  8_9_17


% read in data from excel
[ndata,text,alldata] = xlsread('~/drive/grad_school/DML_WBR/Sequences_Exp3/sms2/mturk_test.xls');

xls_ixs = [1:3:48];

for i_chunk = xls_ixs
    clear TXT; clear u_txt; clear zs; 
    TXT = text(:,i_chunk:i_chunk+2);

    % get unique answers
    u_txt = unique(TXT);
    zs = zeros(length(u_txt),1);


    for i_u_text = 1:length(u_txt)

        for i_first = 1:size(TXT,1)
            if strcmp(u_txt(i_u_text),TXT(i_first,1))
                zs(i_u_text) = zs(i_u_text) + 3;
            end % end if 

        end % end i_first 

        for i_second = 1:size(TXT,1)
            if strcmp(u_txt(i_u_text),TXT(i_second,2))
                zs(i_u_text) = zs(i_u_text) + 2;
            end % end if 
        end % end i_second 

        for i_third = 1:size(TXT,1)
            if strcmp(u_txt(i_u_text),TXT(i_third,3))
                zs(i_u_text) = zs(i_u_text) + 1;
            end % end if 
        end % end i_third 


    end % end i_u_text

    file_num = i_chunk;
    u_txt(:,2) = num2cell(zs);

    FID = fopen(sprintf('mt_norms_weights_%d.dat',file_num),'w');
    formatSpec = '%s %d \n';
    for irow = 1:size(u_txt,1)
        fprintf(FID, formatSpec, u_txt{irow,:});
    end
    fclose(FID);

end % end ichunk
