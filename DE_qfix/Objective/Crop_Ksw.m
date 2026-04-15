function [Kswi]=Crop_Ksw(fieldcapacityi,wiltingi,thetai)
    %Ë®·ÖÐ²ÆÈ¼ÆËã
    if thetai >= 0.9 * fieldcapacityi
        Kswi = 1;
    elseif  thetai < wiltingi
        Kswi = 0;
    else
        Kswi = (0.9 * thetai - wiltingi) / (0.9 * fieldcapacityi - wiltingi);
    end
end


