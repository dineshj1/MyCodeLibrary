% general purpose figure saving/printing
function storeFigs(figHandle, fileName)
   fprintf('Saving to %s\n', fileName);
   set(figHandle, 'PaperPositionMode', 'auto'); % preserves screen size
   [~, ~, extn]=fileparts(fileName);
   if strcmpi(extn,'.fig')
     saveas(figHandle, fileName);
   else
     switch lower(extn)
       case '.eps'
         printheader='-depsc';
       case '.png'
         printheader='-dpng';
       case '.pdf'
         printheader='-dpdf';
       case '.jpg'
         printheader='-djpeg';
       case '.jpeg'
         printheader='-djpg';
       case '.bmp'
         printheader='-dbmp';
       otherwise
         error('Unknown figure format');    
     end
     print(figHandle, printheader, fileName);
   end   
end
 
