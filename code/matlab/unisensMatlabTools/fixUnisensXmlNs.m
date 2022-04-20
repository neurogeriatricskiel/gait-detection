function fixUnisensXmlNs (unisensPath)
% FIXUNISENSXMLNS fix unisens namespace in unisens.xml
%
% This is a workaround: When using the unisens library in matlab sometimes the unisens namescpae 
% is removed when the unisens.xml file is written. 
% Read the unisens.xml file, add the xmlns attribute 
% for the unisens namespace when necessary and save the file again.

% Copyright 2019 movisens GmbH, Germany

xmlDoc = xmlread([(unisensPath), filesep, 'unisens.xml']);

xmlDocumentElement = xmlDoc.getDocumentElement;

if (isempty(xmlDocumentElement.getAttributes.getNamedItem('xmlns')))
    xmlDocumentElement.setAttribute('xmlns', 'http://www.unisens.org/unisens2.0');
    xmlwrite([(unisensPath), filesep, 'unisens.xml'], xmlDoc)
end