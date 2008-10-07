module AppUtil (
	KeyState(..),
	isPressing,
	KeyProc,
	keyProc,

	PadBtn(..),
	padPressing,
	padPressed,

	ImageResource,
	loadImageResource,
	releaseImageResource,
	getImageSurface,
	putimg,

	cellCrd,
	Rect(..),
	ishit
) where

import Multimedia.SDL (Surface, SDLKey(..), loadBMP, freeSurface, surfacePixelFormat, displayFormat, pfPalette, setColorKey, SurfaceFlag(..), blitSurface, pt)
import Data.Maybe (fromJust)

import Const
import Images

-- キーボード処理

data KeyState =
	Pushed | Pushing | Released | Releasing
	deriving (Eq)

isPressing Pushed  = True
isPressing Pushing = True
isPressing _       = False

type KeyProc = SDLKey -> KeyState

keyProc :: [SDLKey] -> [SDLKey] -> KeyProc
keyProc bef cur k
	| not bp && not cp = Releasing
	| not bp && cp     = Pushed
	| bp     && not cp = Released
	| bp     && cp     = Pushing
	where
		bp = k `elem` bef
		cp = k `elem` cur


-- パッド

data PadBtn =
	PadU | PadD | PadL | PadR | PadA | PadB
	deriving (Eq)

padPressing kp btn = any (isPressing . kp) $ mapSDLKey btn
padPressed kp btn = any ((== Pushed) . kp) $ mapSDLKey btn

mapSDLKey PadU = [SDLK_UP, SDLK_i]
mapSDLKey PadD = [SDLK_DOWN, SDLK_k]
mapSDLKey PadL = [SDLK_LEFT, SDLK_j]
mapSDLKey PadR = [SDLK_RIGHT, SDLK_l]
mapSDLKey PadA = [SDLK_SPACE, SDLK_z]
mapSDLKey PadB = [SDLK_LSHIFT, SDLK_RSHIFT]



-- 画像リソース
type ImageResource = [(ImageType, Surface)]


-- 画像リソース読み込み
loadImageResource :: [ImageType] -> IO ImageResource
loadImageResource = mapM load
	where
		load imgtype = do
			sur <- loadBMP $ ("data/img/" ++) $ imageFn imgtype
			setNuki sur
			converted <- displayFormat sur
			freeSurface sur
			return (imgtype, converted)

		setNuki sur = do
			let fmt = surfacePixelFormat sur
			if not $ null $ pfPalette fmt
				then setColorKey sur [SRCCOLORKEY] 0 >> return ()	-- パレット０番目をぬき色に
				else return ()

releaseImageResource :: ImageResource -> IO ()
releaseImageResource = mapM_ (\(t, sur) -> freeSurface sur)

getImageSurface :: ImageResource -> ImageType -> Surface
getImageSurface imgres = fromJust . flip lookup imgres

putimg :: Surface -> ImageResource -> ImageType -> Int -> Int -> IO ()
putimg sur imgres imgtype x y = do
	blitSurface (getImageSurface imgres imgtype) Nothing sur (pt x y)
	return ()


-- 固定座標系からセル座標系に
cellCrd :: Int -> Int
cellCrd x = x `div` (chrSize * one)



-- ========
data Rect = Rect Int Int Int Int


ishit :: Rect -> Rect -> Bool
ishit (Rect l1 t1 r1 b1) (Rect l2 t2 r2 b2) =
	l1 < r2 && t1 < b2 && l2 < r1 && t2 < b1
