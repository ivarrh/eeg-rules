function myExperiment
try
    %% ----------------------
    % Setup
    % -----------------------
    AssertOpenGL;
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 0);
    HideCursor;
    KbName('UnifyKeyNames');

    subjID = input('Subject ID: ','s');
    outdir = fullfile(pwd,'data');
    if ~exist(outdir,'dir'), mkdir(outdir); end
    timestamp = datestr(now,'yyyymmdd_HHMMSS');
    outfile_mat = fullfile(outdir, sprintf('%s_%s.mat', subjID, timestamp));
    outfile_csv = fullfile(outdir, sprintf('%s_%s.csv', subjID, timestamp));

    % Screen
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    grey  = white/2;
    [win, winRect] = PsychImaging('OpenWindow', screenNumber, grey);
    [xCenter, yCenter] = RectCenter(winRect);

    topPriorityLevel = MaxPriority(win);
    Priority(topPriorityLevel);

    %% ----------------------
    % Audio setup
    % -----------------------
    InitializePsychSound(1); % 1 = try for low latency
    nrchannels = 2;
    freq = 44100;
    pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);

    %% ----------------------
    % Trial setup
    % -----------------------
    audioFolder = fullfile(pwd, 'audio'); % your audio folder
    files = dir(fullfile(audioFolder, '*.wav')); % assumes .wav files
    nTrials = length(files);
    files = files(randperm(nTrials)); % randomize order

    trials = struct();
    for t = 1:nTrials
        trials(t).filename = fullfile(audioFolder, files(t).name);
        trials(t).onset    = NaN;
        trials(t).rt       = NaN;
        trials(t).response = NaN;
    end

    %% ----------------------
    % Instructions
    % -----------------------
    DrawFormattedText(win, 'Bienvenido!\n\nEn cada ensayo escucharás un audio.\n\nDespués responde a la pregunta.\n\nPulsa cualquier tecla para continuar.', ...
        'center', 'center', white, 70);
    Screen('Flip', win);
    KbStrokeWait;

    % Ready screen
    DrawFormattedText(win, '¿Estás listo?\n\nPulsa la barra espaciadora para comenzar.', ...
        'center', 'center', white);
    Screen('Flip', win);
    % Wait specifically for space bar
    while 1
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('space'))
                break;
            elseif keyCode(KbName('ESCAPE'))
                error('Experiment terminated at ready screen.');
            end
        end
    end

    %% ----------------------
    % Trial loop
    % -----------------------
    for t = 1:nTrials
        % Load audio file
        [y, fs] = audioread(trials(t).filename);  % y = samples x channels
        if size(y,2) == 1
            y = [y'; y'];   % make 2 rows (channels) for stereo)
        else
            y = y';         % transpose for stereo already
        end
        
        % Open PsychPortAudio with correct sampling rate
        pahandle = PsychPortAudio('Open', [], [], 0, fs, size(y,1));

        % Playback
        PsychPortAudio('FillBuffer', pahandle, y);
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        % trials(t).onset = startTime;

        % Wait until finished
        WaitSecs(length(y)/freq + 0.1);

        % Prompt
        DrawFormattedText(win, '¿Esta persona incumplió la norma?\n\nE = Sí     I = No\n\n(ESC para salir)', ...
            'center', 'center', white, 70);
        Screen('Flip', win);

        % Collect response
        resp = [];
        rt = NaN;
        tStart = GetSecs;
        while 1
            [keyIsDown, keyTime, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(KbName('ESCAPE'))
                    disp('ESC pressed — exiting experiment.');
                    save(outfile_mat, 'trials', 'subjID');
                    error('Experiment terminated by user.');
                elseif keyCode(KbName('E'))
                    resp = 'SI';
                    rt = keyTime - tStart;
                    break;
                elseif keyCode(KbName('I'))
                    resp = 'NO';
                    rt = keyTime - tStart;
                    break;
                end
            end
        end

        trials(t).response = resp;
        trials(t).rt = rt;

        % Save after each trial
        save(outfile_mat, 'trials', 'subjID');

        % Save/update CSV
        fid = fopen(outfile_csv, 'w');
        fprintf(fid, 'trial,filename,onset,response,rt\n');
        for k = 1:t
            fprintf(fid, '%d,%s,%.6f,%s,%.4f\n', k, trials(k).filename, ...
                trials(k).onset, string(trials(k).response), trials(k).rt);
        end
        fclose(fid);

        % ITI
        WaitSecs(0.5 + rand*0.5);
    end

    %% ----------------------
    % End screen
    % -----------------------
    DrawFormattedText(win, 'Gracias!\n\nFin del experimento.', 'center', 'center', white);
    Screen('Flip', win);
    KbStrokeWait;

    % Cleanup
    PsychPortAudio('Close', pahandle);
    Priority(0);
    ShowCursor;
    Screen('CloseAll');

catch ME
    % Emergency cleanup
    PsychPortAudio('Close');
    Priority(0);
    ShowCursor;
    Screen('CloseAll');
    rethrow(ME);
end
end
