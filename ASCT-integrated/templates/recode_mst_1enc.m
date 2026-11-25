%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Recodding triggers %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% The script provides code which recodes triggers assigned during experiment.
% One has to specify which trigger transforms into which one, and under which circumstances.
% Parameters are:
% - 'trig_config' - trigger configuration for all triggers in given ds (previously obtained by calling 'ft_definetrial', which is done automtically in the code of 'sc_2_SEGM' just beofre calling recodding), and
% - 'seg.final_trig_list' - what is a desired list of triggers (chosen from all triggers) you want to further analyse. They are calculated automatically from desing configuration and shoul dbe passed on to this function
% (during recodding the code needs to have access to all triggers in given recording. Therefore, field 'triggers' concatenates all of the triggers to the desired ones in further analysis)
% Structure 'triggers' chooses only those triggers which were specified for analysis in 'design', [see EX_SETUP script under 'design' structure] )
% structure.
%
% WARNING: each template should be edited accordingly to the experiment requirements
% and saved in the experiment folder with an original name (eg. 'sc_recod_ResDep').
% The name of created script is subsequently provided as a parameter in 'EX_SETUP', which passes it further to 'sc_2_SEGM' script.
% ('sc_2_SEGM' script searches for the recodding code under 'recod_fun_to_call = ')

% NOTE: It is important to mentione that trig_config is needed for lasting trigger change.
% This structure is further used as a parameter in 'ft_preprocessing'!


% function [trig_config] = Recoding(trig_config, seg, ds)
function [trig_config] = Recoding(trig_config, infile)


% removing triggers other than listed as seg.origTrig which helps to get
% rid of ghost triggers if any
for tr = length(trig_config.event):-1:1
    if ~any( trig_config.orig_trig_list == trig_config.event(tr).value )
        trig_config.event(tr) = [];
        % trig_config.trl(tr,:) = [];
    end
end

%% actual recoding of triggers

% here we code whether response is correct or not based on previous event (tr-1)
% therefore we loop from second event, as stimulus must precede the response 
% we initially do this on the event structure, adjusting trl later on

for tr = 2 : length(trig_config.event)   

    if trig_config.event(tr).value==1 && trig_config.event(tr-1).value==11   % after indoor: corr 6, incorr 1
        trig_config.event(tr).value=6;
    end

    if trig_config.event(tr).value==3 && trig_config.event(tr-1).value==33  % after outdoor: corr 8, incorr 3
        trig_config.event(tr).value=8;
    end

end

%% post recoding

% propgating recoded event values to trl 
for tr = 1 : length(trig_config.event)
    trig_config.trl(tr,4) = trig_config.event(tr).value;
end

% removing out of interest triggers
for tr = length(trig_config.event):-1:1
    if ~any( trig_config.final_trig_list == trig_config.event(tr).value )
        trig_config.event(tr) = [];
        trig_config.trl(tr,:) = [];
    end
end


end




