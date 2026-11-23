function sc_classify_predict(inFile, outFile, modelFile)
% A wrapper function for Predict (to mittigate exclusivity of DL toolbox)

    S = load(inFile, 'ims', 'featTbl');
    M = load(modelFile);                      % ten sam plik, z którego teraz budujesz Mods

    pImg  = predict(M.convModel.Model_Net, S.ims, ...
                    'MiniBatchSize', 64, 'ExecutionEnvironment', 'cpu');
    pFeat = predict(M.featModel.Model_Net, S.featTbl, ...
                    'ExecutionEnvironment', 'cpu');

    save(outFile, 'pImg', 'pFeat');
end