% myExperiment.m
% Minimal Psychtoolbox experiment template
% Save as myExperiment.m and run from MATLAB

function myExperiment
try
    %% ----------------------
    % Basic PTB setup
    % -----------------------
    AssertOpenGL;                     % require OpenGL
    PsychDefaultSetup(2);             % unify key names, normalized colors, etc.
    Screen('Preference', 'SkipSyncTests', 0); % set 1 only for debugging (not recommended)
    HideCursor;
    KbName('UnifyKeyNames');

    %% ----------------------
    % Subject / file info
    % -----------------------
    subjID = input('Subject ID: ','s');
    outdir = fullfile(pwd,'data');
    if ~exist(outdir,'dir'), mkdir(outdir); end
    outfile = fullfile(outdir, sprintf('%s_%s.mat', subjID, datestr(now,'yyyymmdd_HHMMSS')));

    %% ----------------------
    % Screen and colors
    % -----------------------
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    grey = white/2;
    [win, winRect] = PsychImaging('OpenWindow', screenNumber, grey);
    [xCenter, yCenter] = RectCenter(winRect);

    ifi = Screen('GetFlipInterval', win); % frame duration
    topPriorityLevel = MaxPriority(win);
    Priority(topPriorityLevel);

    %% ----------------------
    % Stimuli and trials
    % -----------------------
    % Example: simple text & image stimuli, randomized trials
    nTrials = 40;
    % Create a trials struct array
    trials = struct();
    for t = 1:nTrials
        trials(t).stimType = randi(2);            % 1 = text, 2 = image
        trials(t).stimulus = sprintf('Stim %02d', t);
        trials(t).onset = NaN;
        trials(t).rt = NaN;
        trials(t).response = NaN;
    end
    trials = trials(randperm(nTrials)); % shuffle

    % Preload example image (optional)
    % imgTexture = [];
    % img = imread('example.png'); imgTexture = Screen('MakeTexture', win, img);

    %% ----------------------
    % Instructions
    % -----------------------
    DrawFormattedText(win, 'Welcome!\n\nPress any key to start.', 'center', 'center', white);
    Screen('Flip', win);
    KbStrokeWait;

    WaitSecs(0.5);

    %% ----------------------
    % Main trial loop
    % -----------------------
    for t = 1:nTrials
        % ITI (randomized)
        iti = 0.5 + rand*0.8;
        WaitSecs(iti);

        % Prepare stimulus
        if trials(t).stimType == 1
            DrawFormattedText(win, trials(t).stimulus, 'center', 'center', white);
        else
            % example: draw image texture centered (if loaded)
            % Screen('DrawTexture', win, imgTexture, [], CenterRectOnPointd([0 0 size(img,2) size(img,1)], xCenter, yCenter));
            DrawFormattedText(win, ['[IMAGE ' num2str(t) ']'], 'center', 'center', white);
        end

        % Flip & timestamp
        vbl = Screen('Flip', win);
        trials(t).onset = vbl;   % store onset time (GetSecs not necessary; vbl is GetSecs at flip)

        % Collect response
        resp = [];
        rt = NaN;
        tStart = GetSecs;
        while GetSecs - tStart < 2.0  % 2-second response window
            [keyIsDown, keyTime, keyCode] = KbCheck;
            if keyIsDown
                key = KbName(find(keyCode));
                if iscell(key), key = key{1}; end
                resp = key;
                rt = keyTime - tStart;
                break;
            end
        end
        trials(t).response = resp;
        trials(t).rt = rt;

        % brief feedback (optional)
        if ~isempty(resp)
            DrawFormattedText(win, 'Response recorded', 'center', yCenter+100, white);
            Screen('Flip', win);
            WaitSecs(0.2);
        end

        % Save incrementally (good for long experiments)
        save(outfile, 'trials', 'subjID');
    end

    %% ----------------------
    % End screen and cleanup
    % -----------------------
    DrawFormattedText(win, 'Thank you!\n\nEnd of experiment.', 'center', 'center', white);
    Screen('Flip', win);
    KbStrokeWait;

    % cleanup
    Priority(0);
    ShowCursor;
    Screen('CloseAll');

catch ME
    % If an error happens: close screen, show cursor and rethrow
    Priority(0);
    ShowCursor;
    Screen('CloseAll');
    rethrow(ME);
end
end
