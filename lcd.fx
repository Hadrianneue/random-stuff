/*
 * (C) 2011 Jan-Willem Krans (janwillem32 <at> hotmail.com)
 * (C) 2013 see Authors.txt
 *
 * This file is part of MPC-HC.
 *
 * MPC-HC is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * MPC-HC is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Brightness, contrast and gamma controls for RGB, linearly scaled from top to bottom.
// This shader can be run as a screen space pixel shader. It requires compiling with ps_2_0,
// but higher is better see http://en.wikipedia.org/wiki/Pixel_shader to look up what PS version
// your video card supports.
// This shader is meant to work with linear RGB input and output. Regular R'G'B' with
// a video gamma encoding will have to be converted with the linear gamma shaders to work properly.

// Fractions, either decimal or not, are allowed
#include "ReShade.fxh"

uniform float3 BrightnessTop <
	ui_type = "slider";
	ui_min = -10.0;
	ui_max = 10.0;
	ui_step = 0.001;
	ui_label = "Brightness Top [LCD Angle Correction]";
> = float3(0.0,0.0,0.0);

uniform float3 BrightnessBottom <
	ui_type = "slider";
	ui_min = -10.0;
	ui_max = 10.0;
	ui_step = 0.001;
	ui_label = "Brightness Bottom [LCD Angle Correction]";
> = float3(0.0,0.0,0.0);

// RedContrast, GreenContrast and BlueContrast, interval [0, 10], default 1
uniform float3 ContrastTop <
	ui_type = "slider";
	ui_min = -10.0;
	ui_max = 10.0;
	ui_step = 1.0;
	ui_label = "Contrast Top [LCD Angle Correction]";
> = float3(1.0,1.0,1.0);

uniform float3 ContrastBottom <
	ui_type = "slider";
	ui_min = -10.0;
	ui_max = 10.0;
	ui_step = 1.0;
	ui_label = "Contrast Bottom [LCD Angle Correction]";
> = float3(1.0,1.0,1.0);

// RedGamma, GreenGamma and BlueGamma, interval (0, 10], default 1
uniform float3 GammaTop <
	ui_type = "slider";
	ui_min = -10.0;
	ui_max = 10.0;
	ui_step = 0.1;
	ui_label = "Gamma Top [LCD Angle Correction]";
> = float3(0.8,0.8,0.8);

uniform float3 GammaBottom <
	ui_type = "slider";
	ui_min = -10.0;
	ui_max = 10.0;
	ui_step = 0.1;
	ui_label = "Gamma Bottom [LCD Angle Correction]";
> = float3(1.0,1.0,1.0);

sampler2D sColorSRGB
{
	Texture = ReShade::BackBufferTex;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	MipFilter = LINEAR;
	SRGBTexture = true;
};

float4 PS_LCDAngleCorrection(in float4 pos : SV_Position, in float2 txcoord : TEXCOORD) : COLOR
{
	float3 s1 = tex2D(sColorSRGB, txcoord).rgb;
	// original pixel
	float texyi = 1.0 - txcoord.y;
	s1 = s1 * (texyi * ContrastTop.rgb + txcoord.y * ContrastBottom.rgb) + texyi * BrightnessTop.rgb + txcoord.y * BrightnessBottom.rgb;
	// process contrast and brightness on the original pixel
	// preserve the sign bits of RGB values
	float3 sb = sign(s1);
	return (sb*pow(abs(s1), texyi * GammaTop.rgb + txcoord.y * GammaBottom.rgb)).rgbb;
	// process gamma correction and output
}

technique MPC_LCDAngleCorr
{
	pass PS_LCDAngleCorrP1
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_LCDAngleCorrection;
		SRGBWriteEnable = true;
	}
}
