import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Switch,
  FormControlLabel,
  RadioGroup,
  Radio,
  Button,
  Stack,
  Divider
} from '@mui/material';
import { SketchPicker, ColorResult } from 'react-color';
import { useTheme } from '../context/ThemeContext';

const ThemeSettings: React.FC = () => {
  const { 
    themeMode, 
    primaryColor, 
    secondaryColor, 
    fontSize, 
    toggleTheme, 
    updateThemeColors,
    updateFontSettings 
  } = useTheme();

  const [showPrimaryPicker, setShowPrimaryPicker] = React.useState(false);
  const [showSecondaryPicker, setShowSecondaryPicker] = React.useState(false);

  return (
    <Card sx={{ maxWidth: 600, mx: 'auto', mt: 3 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          إعدادات المظهر
        </Typography>
        <Divider sx={{ my: 2 }} />
        
        <Stack spacing={3}>
          {/* Dark Mode Toggle */}
          <FormControlLabel
            control={
              <Switch
                checked={themeMode === 'dark'}
                onChange={toggleTheme}
              />
            }
            label="الوضع الليلي"
          />

          {/* Font Size Selection */}
          <Box>
            <Typography variant="subtitle1" gutterBottom>
              حجم الخط
            </Typography>
            <RadioGroup
              row
              value={fontSize}
              onChange={(e) => updateFontSettings('Cairo, sans-serif', e.target.value as 'small' | 'medium' | 'large')}
            >
              <FormControlLabel value="small" control={<Radio />} label="صغير" />
              <FormControlLabel value="medium" control={<Radio />} label="متوسط" />
              <FormControlLabel value="large" control={<Radio />} label="كبير" />
            </RadioGroup>
          </Box>

          {/* Color Pickers */}
          <Box>
            <Typography variant="subtitle1" gutterBottom>
              الألوان الرئيسية
            </Typography>
            <Stack direction="row" spacing={2}>
              <Box>
                <Button
                  variant="outlined"
                  onClick={() => setShowPrimaryPicker(!showPrimaryPicker)}
                  sx={{
                    backgroundColor: primaryColor,
                    '&:hover': { backgroundColor: primaryColor },
                    width: 100,
                    height: 40
                  }}
                />
                {showPrimaryPicker && (
                  <Box sx={{ position: 'absolute', zIndex: 2 }}>
                    <Box
                      sx={{
                        position: 'fixed',
                        top: 0,
                        right: 0,
                        bottom: 0,
                        left: 0,
                      }}
                      onClick={() => setShowPrimaryPicker(false)}
                    />
                    <SketchPicker
                      color={primaryColor}
                      onChange={(color: ColorResult) => updateThemeColors(color.hex, secondaryColor)}
                    />
                  </Box>
                )}
              </Box>

              <Box>
                <Button
                  variant="outlined"
                  onClick={() => setShowSecondaryPicker(!showSecondaryPicker)}
                  sx={{
                    backgroundColor: secondaryColor,
                    '&:hover': { backgroundColor: secondaryColor },
                    width: 100,
                    height: 40
                  }}
                />
                {showSecondaryPicker && (
                  <Box sx={{ position: 'absolute', zIndex: 2 }}>
                    <Box
                      sx={{
                        position: 'fixed',
                        top: 0,
                        right: 0,
                        bottom: 0,
                        left: 0,
                      }}
                      onClick={() => setShowSecondaryPicker(false)}
                    />
                    <SketchPicker
                      color={secondaryColor}
                      onChange={(color: ColorResult) => updateThemeColors(primaryColor, color.hex)}
                    />
                  </Box>
                )}
              </Box>
            </Stack>
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
};

export default ThemeSettings;
