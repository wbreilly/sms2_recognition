% sms2scan recognition
% Walter Reilly
% last update: 6_7_17
% adapted from: Halle Dimsdale-Zucker 


%% Intro stuff (like cleaning up, etc.)

tic;
clear all;
close all;
fclose('all');
sca;
rand('seed',sum(100*clock));

%% Flags
DEBUGGING_FLAG=0;

%% Script-specific variables

% setting parameters
duration_item_retrieval      = 1000/1000;   % 1000
duration_isi_retrieval       = 4000/1000;   % 3000
duration_blank               = 1500/1000;

%%


subject=input('Enter subject number: ');    % Ask for subject number input first
practice=input('Select 1 for practice, 0 for task: ');

%Instructions text
instruc = 'You will now be presented with verbs and asked\n to recall whether you studied it on the scanning day :\n\n';

%% Initialize file where will write data

fprintf('Setting up data file.\n');

if sub_num < 0 || sub_num > 99
    error('Invalid subject number!!!');
end

recog_dat = sprintf('s%02d_recognition%d.dat',sub_num, cycle_num);
recog_mat = sprintf('s%02d_recognition%d.mat',sub_num, cycle_num);


if fopen(recog_dat,'rt') ~= -1 
    fclose('all');
    yes_or_no = input('Data file already exists! Are you sure you want to overwrite the file? (yes:1 no:0) ');
    if yes_or_no == 0 || isempty(yes_or_no)
        error('Enter a different subject or block number!');
    end
end

% write results into result file
fid_recog = fopen(recog_dat,'wt');

%% Load stim and save subject specific presentation order 

if practice
    % "Read in" stimulus info
   
else
    % Read in stimulus info
    fprintf('Reading in stimuli.\n');
    recog_stim = sprintf('sms2_recognition_stim.txt');
    tmp = readtable(recog_stim, 'ReadVariableNames',false);
    all_stim = table2array(tmp);
    clear tmp
    
    % Determining randomized object order
    sub_stim = Shuffle(all_stim);
    %save stim presentation order
    save(recog_mat, sub_stim);
    
    
end %if


%% INITIZLIAING PSYCHTOOLBOX
    AssertOpenGL;
    % dummy calls to GetSecs/WaitSecs/KbCheck to make sure they are loaded without delays in the wrong moment
    KbCheck;
    WaitSecs(0.1);
    GetSecs;
    % get screenNumber of stimulation display. 
    screens=Screen('Screens');
    screenNumber=max(screens);
    % hide the mouse cursor
    HideCursor;
    black=BlackIndex(screenNumber);
    % open a double buffered fullscreen window on the stimulation screen
    % 'screenNumber' and choose/draw a gray background. 'w' is the handle
    % used to direct all drawing commands to that window - the "Name" of
    % the window. 'wRect' is a rectangle defining the size of the window.
    % See "help PsychRects" for help on such rectangles and useful helper
    % functions:
    [w, wRect]=Screen('OpenWindow',screenNumber,black); %,[0 0 680 480]);  %for testing use
    %get the midpoint (mx, my) of this window
    [mx, my] = RectCenter(wRect);
    %get screen size
    [x_dim, y_dim] = RectSize(wRect);
    % set priority for script execution to realtime priority
    priorityLevel=MaxPriority(w);
    Priority(priorityLevel);

    % prepare fixation cross
    fixCr=zeros(50,50);
    fixCr(24:27,:)=255;
    fixCr(:,24:27)=255;  
    fixposition = [mx-25,my-25,mx+25,my+25];

    % configure keyboard & prepare question message
    KbName('UnifyKeyNames');
    key_rem = KbName('Rightarrow'); 
    key_fam = KbName('Downarrow'); 
    key_new = KbName('Leftarrow');
    % if mod(sub_num,2) == 1
    %     key_yes = KbName('Rightarrow');        
    %     key_no = KbName('Leftarrow');
    % else
    %     key_yes = KbName('Leftarrow');        
    %     key_no = KbName('Rightarrow'); 
    % end

    % study result file headers
    fprintf(fid_recog,strcat('Remember:',KbName(key_rem),'New:',KbName(key_new),'Familiar:',KbName(key_fam),'\n'));
    fprintf(fid_recog,'sub item key_press response rt\n');

    KeyCode = zeros(1,256);
    KeyIsDown = zeros(1,1);
    endrt = zeros(1,1);

    % specify variables
    keybutton = [];
    RECOGNITION = struct;

    % clear screen objects
    Screen('Close');


    %% RECOGNITION 
    RestrictKeysForKbCheck([key_rem,key_new, key_fam]);

    % show study message
    Screen('TextSize', w, 30);
    % prepare message
    DrawFormattedText(w, instruct, 'center','center', WhiteIndex(w));
    % update the display to show the study message
    Screen('Flip', w);
    % wait for mouse click:
    GetClicks(w);


    % update the display to show blank screen for 1.5 seconds
    Screen('Flip', w);
    WaitSecs(duration_blank);
    % draw fixation cross
    fixcross = Screen('MakeTexture',w,fixCr);
    Screen('DrawTexture', w, fixcross,[],fixposition);
    Screen('Flip', w);
    WaitSecs(duration_isi_retrieval);
    
    %%
    
    % pre-set variables 
    default_ans = {'no_resp'};
    stamp_item_retrieval = NaN(length(sub_stim,1));          % create a nx1 matrix to contain item onsets in each study block
    stamp_fixation_retrieval = NaN(length(sub_stim,1));      % create a nx1 matrix to contain onsets of ISI "+"
    response = repmat(default_ans,NaN(length(sub_stim,1)));      % create a nx1 matrix to contain responses for living/nonliving judgments 
    rt = NaN(length(sub_stim,1));                            % create a nx1 matrix to contain rts for judgments
    acc = zeros(length(sub_stim,1));                         % create a nx1 matrix to contain accs for judgments
    keypress = repmat(default_ans,(length(sub_stim,1)));      % create a nx1 matrix to contain pressed keys for judgments
    
        
    %%
    
    for i_word = 1:length(sub_stim)
    
        DrawFormattedText(w, sub_stim{i_word}, 'center','center', WhiteIndex(w));
        [VBLTimestamp stamp_item_retrieval(i_word)] = Screen('Flip', w);

        % manually clear keyboard events 
        KeyCode = zeros(1,256);
        KeyIsDown = zeros(1,1);
        endrt = zeros(1,1);
        % read keyboard events
        while ((GetSecs - stamp_item_retrieval(i_word)) <= duration_item_retrieval)
            if (KeyCode(key_rem)==0 && KeyCode(key_fam)==0) && KeyCode(key_no)==new)
                [KeyIsDown, endrt, KeyCode]=KbCheck;
                WaitSecs(0.001);
            end
        end
        % draw isi fixation
        fixcross = Screen('MakeTexture',w,fixCr);
        Screen('DrawTexture', w, fixcross,[],fixposition);
        [VBLTimestamp stamp_fixation_retrieval(i_word)] = Screen('Flip', w);
        % read keyboard events
        while ((GetSecs - stamp_fixation_retrieval(i_word)) <= duration_isi_retrieval)
            if (KeyCode(key_rem)==0 && KeyCode(key_fam)==0) && KeyCode(key_no)==new)
                [KeyIsDown, endrt, KeyCode]=KbCheck;
                WaitSecs(0.001);
            end
        end

        keybutton = find(KeyCode, 1, 'last');
        if ~isempty(keybutton)
            if strcmp(KbName(keybutton),KbName(key_rem))
                response{i_word} = 'rem';
            elseif strcmp(KbName(keybutton),KbName(key_fam))
                response{i_retrieval_sequence,iitem} = 'fam';
            elseif strcmp(KbName(keybutton),KbName(key_new))
                response{i_retrieval_sequence,iitem} = 'new';
            end
            keypress{i_word} = KbName(keybutton);

    % solve accuracy at a later date


            rt(i_word) = ...
                round(1000*(endrt - stamp_item_retrieval(i_word)));
        end % end if ~isempty

       % sub item key_press response rt
        fprintf(fid_retrieval,'%d %s %s %s %d \n',...
            sub_num,...
            sub_stim{i_word},...
            keypress{i_word},...
            response{i_word},...
            rt(i_word)); 
        
        % save mat
        RECOGNITION.stamp_item_retrieval     = stamp_item_retrieval;
        RECOGNITION.stamp_fixation_retrieval = stamp_fixation_retrieval;
        RECOGNITION.response                 = response;
        RECOGNITION.rt                       = rt;
        RECOGNITION.keypress                 = keypress;
        
        save(recog_mat,'RECOGNITION');
end % end i_word
       
        
   
    
    
    %% Finish up %%
    
% Cleanup at end of experiment
Screen('CloseAll');
ShowCursor;
fclose('all');
Priority(0);
ShowHideWinTaskbarMex(1)

% End of experiment:



 % catch error in case something goes wrong in the 'try' part
% Do same cleanup as at the end of a regular session

Screen('CloseAll');
ShowCursor;
fclose('all');
Priority(0);
ShowHideWinTaskbarMex(1)

psychrethrow(psychlasterror);   % Output the error message that describes the error
