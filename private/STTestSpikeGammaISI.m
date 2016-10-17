function [vtSpikeTimes] = STTestSpikeGammaISI(vtTimeTrace, tLastSpike, nul1, ...
                                              definition, nul2, nul3, fISIVar) %#ok<INUSL,INUSD>

% STTestSpikeGammaISI - FUNCTION Internal spike creation test function
% $Id: STTestSpikeGammaISI.m 9694 2008-06-25 12:28:01Z dylan $
%
% NOT for command-line use

% Usage: [vtSpikeTimes] = STTestSpikeGammaISI(tTimeTrace, tLastSpike, [], ...
%                                             definition, [], [], fISIVar)
%
% 'vtTimeTrace' is a vector of discrete time bins over which to generate the
% spike train.  This may correspond to only a single chunk of the train, or the
% entire train.  These bins are to be used when discrete time bins are required,
% but continuous-time generation algorithms are free to ignore them.  This
% vector does define the limits of the train (or chunk) to be generated.
% 'tLastSpike', if defined, is the time of the last spike in the previous chunk.
% 'definition' is the spike train definition node.  'fISIVar' defines the
% variance in inter-spike-intervals, in seconds.

% Author: Dylan Muir <dylan@ini.phys.ethz.ch>
% Created: 3rd February, 2008
% Copyright (c) 2004, 2005 Dylan Richard Muir

% -- Check arguments

if (nargin < 7)
   disp('*** STTestSpikeGammaISI: Incorrect usage.');
   disp('       This is an internal spike creation test function');
   help private/STTestSpikeGammaISI;
   help private/STSpikeCreationTestDescription;
   return;
end



% -- Estimate some spike train parameters

if (exist('tLastSpike', 'var') && ~isempty(tLastSpike))
   tTrainStart = tLastSpike;
else
   tTrainStart = vtTimeTrace(1);
   tLastSpike = [];
end

tTrainEnd = vtTimeTrace(end);
tTrainLength = tTrainEnd - tTrainStart;
nISIsToGenerate = fix(definition.fMaxFreq * tTrainLength * 1.1);

% - Determine alpha and beta 
fAlpha = (1/definition.fMaxFreq).^2 ./ fISIVar;
fBeta = fAlpha .* definition.fMaxFreq;

% - Check suitability of alpha and beta
if (any(fAlpha < 1))
   disp('--- STTestSpikeGammaISI: Warning: This type of spike train doesn''t');
   disp('       work well unless ''fISIVar'' <= ''fMeanISI''^2.  You may get no');
   disp('       spikes when you instantiate this train.');
end


% -- Generate the spike train

vISIs = [];

tCurrTime = tTrainStart;
while (tCurrTime < tTrainEnd)
   % - Draw some normally-distributed ISIs
   vTheseISIs = gamrnd(fAlpha, 1/fBeta, [1 nISIsToGenerate]);

   % - Trim off negative ISIs
   vTheseISIs(vTheseISIs < 0) = 0;
   vISIs = [vISIs vTheseISIs]; %#ok<AGROW>
   tCurrTime = tCurrTime + sum(vISIs);
end


% -- Parcel out ISIs

% - Convert ISIs to spike times
vtSpikeTimes = cumsum([tLastSpike vISIs]);

% - Pick out the spike times which fall inside the vTimeTrace window
vbSpikesInTime = (vtSpikeTimes > tTrainStart) & (vtSpikeTimes <= tTrainEnd);

% - Include one extra spike, to take us over the vTimeTrace window.  This is so
% that we know for sure we've sampled from time which fills the whole window.
% We can disregard this extra spike at the end of the whole spike train.
nLastSpikeIndex = find(vbSpikesInTime, 1, 'last');
vbSpikesInTime(nLastSpikeIndex+1) = true;

% - Include the spikes which meet these criteria
vtSpikeTimes = vtSpikeTimes(vbSpikesInTime);



% --- END of STTestSpikeGammaISI.m ---







