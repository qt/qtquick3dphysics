// Copyright (c) 2001-2004 NovodeX AG. All rights reserved.
// Copyright (c) 2004-2008 AGEIA Technologies, Inc. All rights reserved.
// SPDX-FileCopyrightText: Copyright (c) 2008-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

#include "foundation/PxIO.h"
#include "extensions/PxExtensionsAPI.h"

#include "ExtDistanceJoint.h"
#include "ExtD6Joint.h"
#include "ExtFixedJoint.h"
#include "ExtPrismaticJoint.h"
#include "ExtRevoluteJoint.h"
#include "ExtSphericalJoint.h"
#include "ExtGearJoint.h"
#include "ExtRackAndPinionJoint.h"

#if PX_SUPPORT_PVD
#include "ExtPvd.h"
#include "PxPvdDataStream.h"
#include "PxPvdClient.h"
#include "PsPvd.h"
#endif

#if PX_SUPPORT_OMNI_PVD
#	include "omnipvd/PxOmniPvd.h"
#	include "omnipvd/OmniPvdPxExtensionsSampler.h"
#endif

using namespace physx;
using namespace physx::pvdsdk;

#if PX_SUPPORT_PVD
struct JointConnectionHandler : public PvdClient
{
	JointConnectionHandler() : mPvd(NULL),mConnected(false){}

	PvdDataStream*		getDataStream()
	{
		return NULL;
	}

	void onPvdConnected()
	{
		PvdDataStream* stream = PvdDataStream::create(mPvd);
		if(stream)
		{
			mConnected = true;
			Ext::Pvd::sendClassDescriptions(*stream);	
			stream->release();
		}
	}

	bool isConnected() const
	{
		return mConnected;
	}

	void onPvdDisconnected()
	{
		mConnected = false;
	}

	void flush()
	{
	}

	PsPvd* mPvd;
	bool mConnected;
};

static JointConnectionHandler gPvdHandler;
#endif

bool PxInitExtensions(PxPhysics& physics, PxPvd* pvd)
{
	PX_ASSERT(&physics.getFoundation() == &PxGetFoundation());
	PX_UNUSED(physics);
	PX_UNUSED(pvd);
	PxIncFoundationRefCount();

#if PX_SUPPORT_PVD
	if(pvd)
	{
		gPvdHandler.mPvd = static_cast<PsPvd*>(pvd);
		gPvdHandler.mPvd->addClient(&gPvdHandler);
	}
#endif

#if PX_SUPPORT_OMNI_PVD
	// If OmniPVD is bound (it is created up front and passed to PxCreatePhysics), create the
	// extensions callback, capture the PxPhysics, and register it with the PxOmniPvd. Its
	// onStartSampling() then fires whenever PxOmniPvd::startSampling() takes a full-state
	// snapshot, re-emitting the live extension joints onto the bound stream -- including the
	// late-attach case, where startSampling() runs long after PxInitExtensions.
	PxOmniPvd* omniPvd = physics.getOmniPvd();
	if (omniPvd && omniPvd->getWriter())
	{
		if (OmniPvdPxExtensionsSampler::createInstance(physics))
		{
			OmniPvdPxExtensionsSampler* sampler = OmniPvdPxExtensionsSampler::getInstance();
			sampler->setOmniPvdInstance(omniPvd);
			// The joint schema is registered lazily in onStartSampling() (via registerClasses()),
			// matching the core sampler, which registers nothing until startSampling(). Registering
			// here would run before the core handle re-numbering and emit before recording is on.
			omniPvd->addEventCallback(*sampler);
		}
	}
#endif
	return true;
}

static PxArray<PxSceneQuerySystem*>*	gExternalSQ = NULL;

void addExternalSQ(PxSceneQuerySystem* added)
{
	if(!gExternalSQ)
		gExternalSQ = new PxArray<PxSceneQuerySystem*>;

	gExternalSQ->pushBack(added);
}

void removeExternalSQ(PxSceneQuerySystem* removed)
{
	if(gExternalSQ)
	{
		const PxU32 nb = gExternalSQ->size();
		for(PxU32 i=0;i<nb;i++)
		{
			PxSceneQuerySystem* sq = (*gExternalSQ)[i];
			if(sq==removed)
			{
				gExternalSQ->replaceWithLast(i);
				return;
			}
		}
	}
}

static void releaseExternalSQ()
{
	if(gExternalSQ)
	{
		PxArray<PxSceneQuerySystem*>* copy = gExternalSQ;
		gExternalSQ = NULL;

		const PxU32 nb = copy->size();
		for(PxU32 i=0;i<nb;i++)
		{
			PxSceneQuerySystem* sq = (*copy)[i];
			sq->release();
		}
		PX_DELETE(copy);
	}
}

void PxCloseExtensions()
{
	releaseExternalSQ();

	PxDecFoundationRefCount();

#if PX_SUPPORT_PVD
	if(gPvdHandler.mConnected)
	{
		PX_ASSERT(gPvdHandler.mPvd);
		gPvdHandler.mPvd->removeClient(&gPvdHandler);
		gPvdHandler.mPvd = NULL;
	}
#endif

#if PX_SUPPORT_OMNI_PVD
	// Unregister the extensions callback from the PxOmniPvd before destroying it, so a later
	// startSampling() snapshot cannot call into freed extension state.
	OmniPvdPxExtensionsSampler* sampler = OmniPvdPxExtensionsSampler::getInstance();
	if (sampler)
	{
		if (PxOmniPvd* omniPvd = sampler->getOmniPvdInstance())
			omniPvd->removeEventCallback(*sampler);
		OmniPvdPxExtensionsSampler::destroyInstance();
	}
#endif
}
