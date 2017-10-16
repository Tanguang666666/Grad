function prat = MilStd5008B(M)
%MILSTD5008B Stagnation pressure ratio standard inlet calculation

if (M < 1)
    prat = 1;
elseif (M >= 1) && (M < 5)
    prat = 1 - 0.075 * (M - 1)^1.35;
else
    prat = 800 / (M^4 + 935);
end

end

